function! gina#action#patch#define(binder) abort
  let params = {
        \ 'description': 'Open 3-way diff for patching changes to the index',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \}
  call a:binder.define('patch', function('s:on_patch'), extend({
        \ 'options': {},
        \}, params))
  call a:binder.define('patch:above', function('s:on_patch'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'leftabove new'},
        \}, params))
  call a:binder.define('patch:below', function('s:on_patch'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'belowright new'},
        \}, params))
  call a:binder.define('patch:left', function('s:on_patch'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'leftabove vnew'},
        \}, params))
  call a:binder.define('patch:right', function('s:on_patch'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'belowright vnew'},
        \}, params))
  call a:binder.define('patch:tab', function('s:on_patch'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'tabedit'},
        \}, params))
endfunction


" Private --------------------------------------------------------------------
function! s:on_patch(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  for candidate in a:candidates
    execute printf(
          \ '%s Gina patch %s %s %s %s',
          \ options.mods,
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(get(candidate, 'line'), '--line='),
          \ gina#util#shellescape(get(candidate, 'col'), '--col='),
          \ gina#util#shellescape(candidate.path),
          \)
  endfor
endfunction
