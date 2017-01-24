function! gina#action#diff#define(binder, ...) abort
  call a:binder.define('diff', function('s:on_diff'), {
        \ 'description': 'Open a diff content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': {},
        \})
  call a:binder.define('diff:above', function('s:on_diff'), {
        \ 'description': 'Open a diff content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'leftabove new' },
        \})
  call a:binder.define('diff:below', function('s:on_diff'), {
        \ 'description': 'Open a diff content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'belowright new' },
        \})
  call a:binder.define('diff:left', function('s:on_diff'), {
        \ 'description': 'Open a diff content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'leftabove vnew' },
        \})
  call a:binder.define('diff:right', function('s:on_diff'), {
        \ 'description': 'Open a diff content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'belowright vnew' },
        \})
  call a:binder.define('diff:tab', function('s:on_diff'), {
        \ 'description': 'Open a diff content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'tabedit' },
        \})
  call a:binder.define('diff:preview', function('s:on_diff'), {
        \ 'description': 'Open a diff content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'pedit' },
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_diff(candidates, options) abort
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
    let cached = get(candidate, 'sign', '!!') !~# '^\%(??\|!!\|.\w\)$'
    execute printf(
          \ 'Gina diff %s %s %s -- %s',
          \ cached ? '--cached' : '',
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(get(candidate, 'commit', commit)),
          \ gina#util#fnameescape(get(candidate, 'path', path)),
          \)
  endfor
endfunction
