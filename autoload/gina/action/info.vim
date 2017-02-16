function! gina#action#info#define(binder) abort
  call a:binder.define('info', function('s:on_info'), {
        \ 'description': 'Show a commit info',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['revision'],
        \ 'options': {},
        \})
  call a:binder.define('info:above', function('s:on_info'), {
        \ 'description': 'Show a commit info',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['revision'],
        \ 'options': { 'opener': 'leftabove new' },
        \})
  call a:binder.define('info:below', function('s:on_info'), {
        \ 'description': 'Show a commit info',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['revision'],
        \ 'options': { 'opener': 'belowright new' },
        \})
  call a:binder.define('info:left', function('s:on_info'), {
        \ 'description': 'Show a commit info',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['revision'],
        \ 'options': { 'opener': 'leftabove vnew' },
        \})
  call a:binder.define('info:right', function('s:on_info'), {
        \ 'description': 'Show a commit info',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['revision'],
        \ 'options': { 'opener': 'belowright vnew' },
        \})
  call a:binder.define('info:tab', function('s:on_info'), {
        \ 'description': 'Show a commit info',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['revision'],
        \ 'options': { 'opener': 'tabedit' },
        \})
  call a:binder.define('info:preview', function('s:on_info'), {
        \ 'description': 'Show a commit info',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['revision'],
        \ 'options': { 'opener': 'pedit' },
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_info(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  for candidate in a:candidates
    execute printf(
          \ 'Gina info %s %s -- %s',
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(candidate.revision),
          \ gina#util#shellescape(get(candidate, 'path', '')),
          \)
  endfor
endfunction
