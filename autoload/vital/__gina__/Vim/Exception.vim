let s:handlers = []

function! s:_vital_loaded(V) abort
  let s:Console = a:V.import('Vim.Console')
  let s:Guard = a:V.import('Vim.Guard')
endfunction

function! s:_vital_depends() abort
  return ['Vim.Console', 'Vim.Guard']
endfunction

function! s:_vital_created(module) abort
  let a:module.handlers = []
  call a:module.register(s:get_default_handler())
endfunction

function! s:_throw(category, msg) abort
  if a:category ==# 'Info'
    let v:statusmsg = a:msg
  elseif a:category ==# 'Warning'
    let v:warningmsg = a:msg
  elseif a:category =~# '^\%(Error\|Critical\)$'
    let v:errmsg = a:msg
  endif
  return printf(
        \ 'vital: Vim.Exception: %s: %s',
        \ a:category,
        \ a:msg,
        \)
endfunction

function! s:info(msg) abort
  return s:_throw('Info', a:msg)
endfunction

function! s:warn(msg) abort
  return s:_throw('Warning', a:msg)
endfunction

function! s:error(msg) abort
  return s:_throw('Error', a:msg)
endfunction

function! s:critical(msg) abort
  return s:_throw('Critical', a:msg)
endfunction

function! s:handle(...) abort dict
  let l:exception = get(a:000, 0, v:exception)
  for Handler in reverse(copy(self.handlers))
    if call(Handler, [l:exception])
      return
    endif
  endfor
  throw l:exception
endfunction

function! s:call(funcref, args, ...) abort dict
  let guard = s:Guard.store([[self.handlers]])
  let instance = get(a:000, 0, 0)
  try
    if type(instance) == type({})
      return call(a:funcref, a:args, instance)
    else
      return call(a:funcref, a:args)
    endif
  catch /^vital: Vim\.Exception: /
    call self.handle()
  finally
    call guard.restore()
  endtry
endfunction

function! s:register(handler) abort dict
  call add(self.handlers, a:handler)
endfunction

function! s:unregister(handler) abort dict
  let index = index(self.handlers, a:handler)
  if index != -1
    call remove(self.handlers, index)
  endif
endfunction

function! s:get_default_handler() abort
  return function('s:_default_handler')
endfunction


" Handler --------------------------------------------------------------------
function! s:_default_handler(exception) abort
  let m = matchlist(a:exception, '^vital: Vim\.Exception: \(\w\+\): \(.*\)')
  if len(m)
    let category = m[1]
    let message = m[2]
    if category ==# 'Info'
      redraw
      call s:Console.info(message)
      call s:Console.debug(v:throwpoint)
      return 1
    elseif category ==# 'Warning'
      redraw
      call s:Console.warn(message)
      call s:Console.debug(v:throwpoint)
      return 1
    elseif category ==# 'Error'
      redraw
      call s:Console.error(message)
      call s:Console.debug(v:throwpoint)
      return 1
    elseif category ==# 'Critical'
      redraw
      call s:Console.error(message)
      call s:Console.error(v:throwpoint)
    endif
    throw message
  endif
  return 0
endfunction
