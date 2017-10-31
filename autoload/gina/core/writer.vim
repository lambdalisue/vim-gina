let s:Writer = vital#gina#import('Vim.Buffer.Writer')


function! gina#core#writer#new(...) abort
  let writer = call(s:Writer.new, a:000, s:Writer)
  let writer.updatetime = g:gina#core#writer#updatetime
  return writer
endfunction

function! gina#core#writer#assign_content(...) abort
  return call(s:Writer.assign_content, a:000, s:Writer)
endfunction

function! gina#core#writer#extend_content(...) abort
  return call(s:Writer.extend_content, a:000, s:Writer)
endfunction


call gina#config(expand('<sfile>'), {
      \ 'updatetime': 100,
      \})
