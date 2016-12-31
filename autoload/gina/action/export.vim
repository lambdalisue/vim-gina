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
  let selection = get(a:candidate, 'selection', [])
  return {
        \ 'filename': a:candidate.path,
        \ 'lnum': get(get(selection, 0, []), 0, 1),
        \ 'col': get(get(selection, 0, []), 1, 1),
        \ 'text': s:String.remove_ansi_sequences(a:candidate.word),
        \}
endfunction
