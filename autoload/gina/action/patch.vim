function! gina#action#patch#define(binder) abort
  call a:binder.define('patch', function('s:on_patch'), {
        \ 'description': 'Patch a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': {},
        \})
  call a:binder.define('patch:above', function('s:on_patch'), {
        \ 'description': 'Patch a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'leftabove new' },
        \})
  call a:binder.define('patch:below', function('s:on_patch'), {
        \ 'description': 'Patch a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'belowright new' },
        \})
  call a:binder.define('patch:left', function('s:on_patch'), {
        \ 'description': 'Patch a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'leftabove vnew' },
        \})
  call a:binder.define('patch:right', function('s:on_patch'), {
        \ 'description': 'Patch a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'belowright vnew' },
        \})
  call a:binder.define('patch:tab', function('s:on_patch'), {
        \ 'description': 'Patch a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'tabedit' },
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_patch(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  for candidate in a:candidates
    execute printf(
          \ 'Gina patch %s %s %s -- %s',
          \ gina#util#fnameescape(options.opener, '--opener='),
          \ gina#util#fnameescape(get(candidate, 'line'), '--line='),
          \ gina#util#fnameescape(get(candidate, 'col'), '--col='),
          \ gina#util#fnameescape(candidate.path),
          \)
  endfor
endfunction
