function! gina#action#chaperon#define(binder) abort
  let params = {
        \ 'description': 'Open 3-way diff for solving conflicts',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path', 'sign'],
        \}
  call a:binder.define('chaperon', function('s:on_chaperon'), extend({
        \ 'options': {},
        \}, params))
  call a:binder.define('chaperon:above', function('s:on_chaperon'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'leftabove new'},
        \}, params))
  call a:binder.define('chaperon:below', function('s:on_chaperon'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'belowright new'},
        \}, params))
  call a:binder.define('chaperon:left', function('s:on_chaperon'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'leftabove vnew'},
        \}, params))
  call a:binder.define('chaperon:right', function('s:on_chaperon'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'belowright vnew'},
        \}, params))
  call a:binder.define('chaperon:tab', function('s:on_chaperon'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'tabedit'},
        \}, params))
endfunction


" Private --------------------------------------------------------------------
function! s:on_chaperon(candidates, options) abort
  let candidates = filter(copy(a:candidates), 'v:val.sign ==# ''UU''')
  if empty(candidates)
    return
  endif
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  for candidate in candidates
    execute printf(
          \ '%s Gina chaperon %s %s %s %s',
          \ options.mods,
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(get(candidate, 'line'), '--line='),
          \ gina#util#shellescape(get(candidate, 'col'), '--col='),
          \ gina#util#shellescape(candidate.path),
          \)
  endfor
endfunction
