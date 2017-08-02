let s:Exception = vital#gina#import('Vim.Exception')


function! gina#core#exception#cancel() abort
  return call(s:Exception.message, ['Cancel', ''], s:Exception)
endfunction

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


" Private --------------------------------------------------------------------
function! s:exception_handler(exception) abort
  let category = matchstr(a:exception, '^vital: Vim\.Exception: \zs\w\+\ze: .*')
  if category ==# 'Cancel'
    return 1
  endif
  return 0
endfunction

call s:Exception.register(function('s:exception_handler'))
