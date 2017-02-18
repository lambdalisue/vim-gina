let s:Console = vital#gina#import('Vim.Console')
let s:Queue = vital#gina#import('Data.Queue')
let s:Console.prefix = '[gina] '


if has('nvim')
  function! gina#core#console#message(msg) abort
    return gina#core#console#echo(a:msg)
  endfunction
else
  " NOTE:
  " Vim 8.0.0329 will not echo entire message which was invoked in timer/job.
  " While echo pipe is used to inform the result of the process to a user, it
  " is kind critical so use autocmd to forcedly invoke message.
  let s:message_queue = s:Queue.new()
  function! gina#core#console#message(msg) abort
    augroup gina_core_console_message_internal
      autocmd! *
      autocmd CursorMoved * call s:message_callback()
      autocmd CursorHold  * call s:message_callback()
      autocmd InsertEnter * call s:message_callback()
    augroup END
    call s:message_queue.put(a:msg)
  endfunction

  function! s:message_callback() abort
    let msg = s:message_queue.get()
    while msg isnot# v:null
      call gina#core#console#echo(msg)
      let msg = s:message_queue.get()
    endwhile
    augroup gina_core_console_message_internal
      autocmd! *
    augroup END
  endfunction
endif

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
