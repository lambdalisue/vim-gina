let s:Console = vital#gina#import('Vim.Console')
let s:Console.prefix = '[gina] '


function! gina#core#console#echo(...) abort
  return call(s:Console.echo, a:000, s:Console)
endfunction

function! gina#core#console#echon(...) abort
  return call(s:Console.echon, a:000, s:Console)
endfunction

function! gina#core#console#echomsg(...) abort
  return call(s:Console.echomsg, a:000, s:Console)
endfunction

function! gina#core#console#debug(...) abort
  return call(s:Console.debug, a:000, s:Console)
endfunction

function! gina#core#console#info(...) abort
  return call(s:Console.info, a:000, s:Console)
endfunction

function! gina#core#console#warn(...) abort
  return call(s:Console.warn, a:000, s:Console)
endfunction

function! gina#core#console#error(...) abort
  return call(s:Console.error, a:000, s:Console)
endfunction

function! gina#core#console#ask(...) abort
  return call(s:Console.ask, a:000, s:Console)
endfunction

function! gina#core#console#confirm(...) abort
  return call(s:Console.confirm, a:000, s:Console)
endfunction
