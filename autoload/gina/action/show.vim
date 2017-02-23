function! gina#action#show#define(binder) abort
  call a:binder.define('show', function('s:on_show'), {
        \ 'description': 'Open a file in the index or commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': {},
        \})
  call a:binder.define('show:above', function('s:on_show'), {
        \ 'description': 'Open a file in the index or commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'leftabove new' },
        \})
  call a:binder.define('show:below', function('s:on_show'), {
        \ 'description': 'Open a file in the index or commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'belowright new' },
        \})
  call a:binder.define('show:left', function('s:on_show'), {
        \ 'description': 'Open a file in the index or commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'leftabove vnew' },
        \})
  call a:binder.define('show:right', function('s:on_show'), {
        \ 'description': 'Open a file in the index or commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'belowright vnew' },
        \})
  call a:binder.define('show:tab', function('s:on_show'), {
        \ 'description': 'Open a file in the index or commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'tabedit' },
        \})
  call a:binder.define('show:preview', function('s:on_show'), {
        \ 'description': 'Open a file in the index or commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'pedit' },
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_show(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  for candidate in a:candidates
    let treeish = gina#core#treeish#build(
          \ gina#util#get(candidate, 'rev'),
          \ candidate.path,
          \)
    execute printf(
          \ 'Gina show %s %s %s %s',
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(get(candidate, 'line'), '--line='),
          \ gina#util#shellescape(get(candidate, 'col'), '--col='),
          \ gina#util#shellescape(treeish),
          \)
  endfor
endfunction
