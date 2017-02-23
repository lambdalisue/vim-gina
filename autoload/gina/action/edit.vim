function! gina#action#edit#define(binder) abort
  call a:binder.define('edit', function('s:on_edit'), {
        \ 'description': 'Open and edit a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': {},
        \})
  call a:binder.define('edit:above', function('s:on_edit'), {
        \ 'description': 'Open and edit a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'leftabove new' },
        \})
  call a:binder.define('edit:below', function('s:on_edit'), {
        \ 'description': 'Open and edit a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'belowright new' },
        \})
  call a:binder.define('edit:left', function('s:on_edit'), {
        \ 'description': 'Open and edit a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'leftabove vnew' },
        \})
  call a:binder.define('edit:right', function('s:on_edit'), {
        \ 'description': 'Open and edit a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'belowright vnew' },
        \})
  call a:binder.define('edit:tab', function('s:on_edit'), {
        \ 'description': 'Open and edit a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'tabedit' },
        \})
  call a:binder.define('edit:preview', function('s:on_edit'), {
        \ 'description': 'Open and edit a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'pedit' },
        \})
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
