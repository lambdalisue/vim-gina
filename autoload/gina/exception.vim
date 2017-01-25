let s:Console = vital#gina#import('Vim.Console')
let s:Exception = vital#gina#import('Vim.Exception')


function! gina#exception#info(msg) abort
  return call(s:Exception.info, [a:msg], s:Exception)
endfunction

function! gina#exception#warn(msg) abort
  return call(s:Exception.warn, [a:msg], s:Exception)
endfunction

function! gina#exception#error(msg) abort
  return call(s:Exception.error, [a:msg], s:Exception)
endfunction

function! gina#exception#critical(msg) abort
  return call(s:Exception.critical, [a:msg], s:Exception)
endfunction

function! gina#exception#call(funcref, args, ...) abort
  return call(s:Exception.call, [a:funcref, a:args] + a:000, s:Exception)
endfunction

function! gina#exception#register(handler) abort
  return call(s:Exception.register, [a:handler], s:Exception)
endfunction

function! gina#exception#unregister(handler) abort
  return call(s:Exception.unregister, [a:handler], s:Exception)
endfunction


" Exception handler ----------------------------------------------------------
function! s:exception_handler(exception) abort
  let m = matchlist(
        \ a:exception,
        \ '^vital: Git\.Term: ValidationError: \(.*\)',
        \)
  if !empty(m)
    call s:Console.warn(m[1])
    return 1
  endif
  return 0
endfunction

call gina#exception#register(
      \ function('s:exception_handler')
      \)
