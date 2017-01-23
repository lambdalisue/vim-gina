function! gina#action#compare#define(binder) abort
  call a:binder.define('compare', function('s:on_compare'), {
        \ 'description': 'Compare a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': {},
        \})
  call a:binder.define('compare:above', function('s:on_compare'), {
        \ 'description': 'Compare a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'leftabove new' },
        \})
  call a:binder.define('compare:below', function('s:on_compare'), {
        \ 'description': 'Compare a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'belowright new' },
        \})
  call a:binder.define('compare:left', function('s:on_compare'), {
        \ 'description': 'Compare a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'leftabove vnew' },
        \})
  call a:binder.define('compare:right', function('s:on_compare'), {
        \ 'description': 'Compare a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'belowright vnew' },
        \})
  call a:binder.define('compare:tab', function('s:on_compare'), {
        \ 'description': 'Compare a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'tabedit' },
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_compare(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let git = gina#core#get_or_fail()
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  let params = gina#util#params('%')
  let path = get(params, 'path', '')
  let commit = get(params, 'commit', '')
  for candidate in a:candidates
    let line = get(candidate, 'line', '')
    let col = get(candidate, 'col', '')
    let cached = get(candidate, 'sign', '!!') !~# '^\%(??\|!!\|.\w\)$'
    execute printf(
          \ 'Gina compare %s %s %s %s %s -- %s',
          \ cached ? '--cached' : '',
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(get(candidate, 'line'), '--line='),
          \ gina#util#shellescape(get(candidate, 'col'), '--col='),
          \ gina#util#shellescape(get(candidate, 'commit', commit)),
          \ gina#util#fnameescape(get(candidate, 'path', path)),
          \)
  endfor
endfunction
