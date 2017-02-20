let s:BufferWriter = vital#gina#import('Vim.BufferWriter')


function! gina#core#writer#new(...) abort
  let s:BufferWriter.use_python = g:gina#core#writer#use_python
  let s:BufferWriter.use_python3 = g:gina#core#writer#use_python3
  let writer = call(s:BufferWriter.new, a:000, s:BufferWriter)
  let writer.updatetime = g:gina#core#writer#updatetime
  return writer
endfunction

function! gina#core#writer#assign_content(...) abort
  let s:BufferWriter.use_python = g:gina#core#writer#use_python
  let s:BufferWriter.use_python3 = g:gina#core#writer#use_python3
  return call(s:BufferWriter.assign_content, a:000, s:BufferWriter)
endfunction

function! gina#core#writer#extend_content(...) abort
  let s:BufferWriter.use_python = g:gina#core#writer#use_python
  let s:BufferWriter.use_python3 = g:gina#core#writer#use_python3
  return call(s:BufferWriter.extend_content, a:000, s:BufferWriter)
endfunction


call gina#config(expand('<sfile>'), {
      \ 'updatetime': 10,
      \ 'use_python': 1,
      \ 'use_python3': 1,
      \})
