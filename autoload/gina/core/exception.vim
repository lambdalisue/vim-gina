let s:Console = vital#gina#import('Vim.Console')
let s:Exception = vital#gina#import('Vim.Exception')


function! gina#core#exception#info(msg) abort
  return call(s:Exception.info, [a:msg], s:Exception)
endfunction

function! gina#core#exception#warn(msg) abort
  return call(s:Exception.warn, [a:msg], s:Exception)
endfunction

function! gina#core#exception#error(msg) abort
  return call(s:Exception.error, [a:msg], s:Exception)
endfunction

function! gina#core#exception#critical(msg) abort
  return call(s:Exception.critical, [a:msg], s:Exception)
endfunction

function! gina#core#exception#call(funcref, args, ...) abort
  return call(s:Exception.call, [a:funcref, a:args] + a:000, s:Exception)
endfunction
