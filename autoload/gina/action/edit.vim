function! gina#action#edit#define(binder) abort
  let params = {
        \ 'description': 'Open and edit a content in the working tree',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \}
  call a:binder.define('edit', function('s:on_edit'), extend({
        \ 'options': {},
        \}, params))
  call a:binder.define('edit:above', function('s:on_edit'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'leftabove new'},
        \}, params))
  call a:binder.define('edit:below', function('s:on_edit'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'belowright new'},
        \}, params))
  call a:binder.define('edit:left', function('s:on_edit'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'leftabove vnew'},
        \}, params))
  call a:binder.define('edit:right', function('s:on_edit'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'belowright vnew'},
        \}, params))
  call a:binder.define('edit:tab', function('s:on_edit'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'tabedit'},
        \}, params))
  call a:binder.define('edit:preview', function('s:on_edit'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'pedit'},
        \}, params))
endfunction


" Private --------------------------------------------------------------------
function! s:on_edit(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  for candidate in a:candidates
    execute printf(
          \ 'Gina edit %s %s %s %s',
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(get(candidate, 'line'), '--line='),
          \ gina#util#shellescape(get(candidate, 'col'), '--col='),
          \ gina#util#shellescape(candidate.path),
          \)
  endfor
endfunction
