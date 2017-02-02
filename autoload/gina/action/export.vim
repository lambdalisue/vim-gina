let s:String = vital#gina#import('Data.String')


function! gina#action#export#define(binder) abort
  call a:binder.define('export:quickfix', function('s:on_quickfix'), {
        \ 'description': 'Replace quickfix list with the selected candidates',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'word'],
        \ 'options': {},
        \})
  call a:binder.define('export:quickfix:add', function('s:on_quickfix'), {
        \ 'description': 'Add selected candidates to quickfix list',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'word'],
        \ 'options': { 'replace': 0 },
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_quickfix(candidates, options) abort dict
  let options = extend({
        \ 'replace': 1,
        \}, a:options)
  let candidates = map(
        \ copy(a:candidates),
        \ 's:to_quickfix(v:val)'
        \)
  call setqflist(
        \ candidates,
        \ options.replace ? 'r' : 'a',
        \)
endfunction

function! s:to_quickfix(candidate) abort
  return {
        \ 'filename': a:candidate.path,
        \ 'lnum': get(a:candidate, 'line', 1),
        \ 'col': get(a:candidate, 'col', 1),
        \ 'text': s:String.remove_ansi_sequences(a:candidate.word),
        \}
endfunction
