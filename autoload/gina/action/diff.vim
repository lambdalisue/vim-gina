function! gina#action#diff#define(binder) abort
  let params = {
        \ 'description': 'Open a diff content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \}
  call a:binder.define('diff', function('s:on_diff'), extend({
        \ 'options': {},
        \}, params))
  call a:binder.define('diff:above', function('s:on_diff'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'leftabove new'},
        \}, params))
  call a:binder.define('diff:below', function('s:on_diff'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'belowright new'},
        \}, params))
  call a:binder.define('diff:left', function('s:on_diff'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'leftabove vnew'},
        \}, params))
  call a:binder.define('diff:right', function('s:on_diff'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'belowright vnew'},
        \}, params))
  call a:binder.define('diff:tab', function('s:on_diff'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'tabedit'},
        \}, params))
  call a:binder.define('diff:preview', function('s:on_diff'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'pedit'},
        \}, params))
endfunction


" Private --------------------------------------------------------------------
function! s:on_diff(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  for candidate in a:candidates
    let cached = get(candidate, 'sign', '!!') !~# '^\%(??\|!!\|.\w\)$'
    let treeish = gina#core#treeish#build(
          \ gina#util#get(candidate, 'rev'),
          \ gina#util#get(candidate, 'path', v:null),
          \)
    execute printf(
          \ 'Gina diff %s %s %s',
          \ cached ? '--cached' : '',
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(treeish),
          \)
  endfor
endfunction
