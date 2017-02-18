let s:listeners = {}
let s:middlewares = []


function! s:subscribe(name, listener, ...) abort
  let instance = get(a:000, 0, v:null)
  let s:listeners[a:name] = get(s:listeners, a:name, [])
  call add(s:listeners[a:name], [a:listener, instance])
endfunction

function! s:unsubscribe(name, listener, ...) abort
  let instance = get(a:000, 0, v:null)
  let s:listeners[a:name] = get(s:listeners, a:name, [])
  let index = index(s:listeners[a:name], [a:listener, instance])
  if index != -1
    call remove(s:listeners[a:name], index)
  endif
endfunction

function! s:unsubscribe_all(...) abort
  if a:0 == 0
    let s:listeners = {}
  else
    let s:listeners[a:1] = []
  endif
endfunction

function! s:add_middleware(middleware) abort
  call add(s:middlewares, a:middleware)
endfunction

function! s:remove_middleware(...) abort
  if a:0 == 0
    let s:middlewares = []
  else
    let index = index(s:middlewares, a:1)
    if index != -1
      call remove(s:middlewares, index)
    endif
  endif
endfunction

function! s:emit(name, ...) abort
  let listeners = copy(get(s:listeners, a:name, []))
  let middlewares = map(s:middlewares, 'extend(copy(s:middleware), v:val)')
  for middleware in middlewares
    call call(middleware.on_emit_pre, [a:name, listeners, a:000], middleware)
  endfor
  for [Listener, instance] in listeners
    if empty(instance)
      call call(Listener, a:000)
    else
      call call(Listener, a:000, instance)
    endif
  endfor
  for middleware in middlewares
    call call(middleware.on_emit_post, [a:name, listeners, a:000], middleware)
  endfor
endfunction


" Middleware skeleton --------------------------------------------------------
let s:middleware = {}

function! s:middleware.on_emit_pre(name, listeners, attrs) abort
endfunction

function! s:middleware.on_emit_post(name, listeners, attrs) abort
endfunction
