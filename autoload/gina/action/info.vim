function! gina#action#info#define(binder) abort
  call a:binder.define('info', function('s:on_info'), {
        \ 'description': 'Show a commit info',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': {},
        \})
  call a:binder.define('info:above', function('s:on_info'), {
        \ 'description': 'Show a commit info',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'leftabove new' },
        \})
  call a:binder.define('info:below', function('s:on_info'), {
        \ 'description': 'Show a commit info',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'belowright new' },
        \})
  call a:binder.define('info:left', function('s:on_info'), {
        \ 'description': 'Show a commit info',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'leftabove vnew' },
        \})
  call a:binder.define('info:right', function('s:on_info'), {
        \ 'description': 'Show a commit info',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'belowright vnew' },
        \})
  call a:binder.define('info:tab', function('s:on_info'), {
        \ 'description': 'Show a commit info',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'tabedit' },
        \})
  call a:binder.define('info:preview', function('s:on_info'), {
        \ 'description': 'Show a commit info',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'pedit' },
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_info(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let git = gina#core#get_or_fail()
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  let params = gina#core#buffer#params('%')
  let path = get(params, 'path', '')
  let revision = get(params, 'revision', '')
  for candidate in a:candidates
    execute printf(
          \ 'Gina info %s %s -- %s',
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(get(candidate, 'revision', revision)),
          \ gina#util#fnameescape(get(candidate, 'path', path)),
          \)
  endfor
endfunction
