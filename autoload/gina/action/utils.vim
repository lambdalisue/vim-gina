function! gina#action#utils#define(binder) abort
  call a:binder.define('utils:yank', function('s:on_yank'), {
        \ 'description': 'Yank the hash of commit under the cursor',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': {},
        \ 'use_marks': 0,
        \ 'clear_marks': 0,
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_yank(candidates, options) abort dict
  if empty(a:candidates)
    return
  endif
  let hash = a:candidates[0].rev
  call gina#util#yank(hash)
endfunction
