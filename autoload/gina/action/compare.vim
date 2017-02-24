function! gina#action#compare#define(binder) abort
  let params = {
        \ 'description': 'Open 2-way diff for comparing the difference',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \}
  call a:binder.define('compare', function('s:on_compare'), extend({
        \ 'options': {},
        \}, params))
  call a:binder.define('compare:above', function('s:on_compare'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'leftabove new'},
        \}, params))
  call a:binder.define('compare:below', function('s:on_compare'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'belowright new'},
        \}, params))
  call a:binder.define('compare:left', function('s:on_compare'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'leftabove vnew'},
        \}, params))
  call a:binder.define('compare:right', function('s:on_compare'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'belowright vnew'},
        \}, params))
  call a:binder.define('compare:tab', function('s:on_compare'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'tabedit'},
        \}, params))
endfunction


" Private --------------------------------------------------------------------
function! s:on_compare(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  for candidate in a:candidates
    let cached = gina#util#get(candidate, 'sign', '!!') !~# '^\%(??\|!!\|.\w\)$'
    let treeish = gina#core#treeish#build(
          \ gina#util#get(candidate, 'rev'),
          \ candidate.path,
          \)
    execute printf(
          \ 'Gina compare %s %s %s %s %s',
          \ cached ? '--cached' : '',
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(get(candidate, 'line'), '--line='),
          \ gina#util#shellescape(get(candidate, 'col'), '--col='),
          \ gina#util#shellescape(treeish),
          \)
  endfor
endfunction
