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
  let m = matchlist(a:exception, '^vital: Vim\.Exception: \(\w\+\): \(.*\)')
  if len(m)
    let category = m[1]
    let message = m[2]
    if category ==# 'Cancel'
      return 1
    elseif category ==# 'Info'
      redraw
      call gina#core#console#info(message)
      call gina#core#console#debug(v:throwpoint)
      return 1
    elseif category ==# 'Warning'
      redraw
      call gina#core#console#warn(message)
      call gina#core#console#debug(v:throwpoint)
      return 1
    elseif category ==# 'Error'
      redraw
      call gina#core#console#error(message)
      call gina#core#console#debug(v:throwpoint)
      return 1
    elseif category ==# 'Critical'
      redraw
      call gina#core#console#error(message)
      call gina#core#console#error(v:throwpoint)
    endif
    throw message
  endif
  return 0
endfunction

call s:Exception.unregister(s:Exception.get_default_handler())
call s:Exception.register(function('s:exception_handler'))
