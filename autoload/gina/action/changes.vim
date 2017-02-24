function! gina#action#changes#define(binder) abort
  call a:binder.define('changes:of', function('s:on_changes'), {
        \ 'description': 'Show changes of the commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': {},
        \})
  call a:binder.define('changes:between', function('s:on_changes'), {
        \ 'description': 'Show changes between the commit and HEAD',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': { 'format': '%s..' },
        \})
  call a:binder.define('changes:from', function('s:on_changes'), {
        \ 'description': 'Show changes from a common ancestor of the commit and HEAD',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': { 'format': '%s...' },
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_changes(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'format': '%s',
        \}, a:options)
  for candidate in a:candidates
    execute printf(
          \ 'Gina changes %s -- %s',
          \ gina#util#shellescape(printf(options.format, candidate.rev)),
          \ gina#util#shellescape(gina#util#get(candidate, 'residual')),
          \)
  endfor
endfunction
