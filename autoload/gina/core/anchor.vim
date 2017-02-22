let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')

function! gina#core#anchor#attach(...) abort
  return call(s:Anchor.attach, a:000, s:Anchor)
endfunction

function! gina#core#anchor#is_suitable(...) abort
  return call(s:Anchor.is_suitable, a:000, s:Anchor)
endfunction

function! gina#core#anchor#focus_if_available(...) abort
  return call(s:Anchor.focus_if_available, a:000, s:Anchor)
endfunction


" Configure Anchor
let s:Anchor.disallow_preview = 1
