function! s:_vital_created(module) abort
  let a:module.listeners = {}
  let a:module.middlewares = []
endfunction


function! s:subscribe(name, listener, ...) abort dict
  let instance = get(a:000, 0, v:null)
  let self.listeners[a:name] = get(self.listeners, a:name, [])
  call add(self.listeners[a:name], [a:listener, instance])
endfunction

function! s:unsubscribe(...) abort dict
  if a:0 == 0
    let self.listeners = {}
  elseif a:0 == 1
    let self.listeners[a:1] = []
  else
    let instance = a:0 == 3 ? a:3 : v:null
    let self.listeners[a:1] = get(self.listeners, a:1, [])
    let index = index(self.listeners[a:1], [a:2, instance])
    if index != -1
      call remove(self.listeners[a:1], index)
    endif
  endif
endfunction

function! s:add_middleware(middleware) abort dict
  call add(self.middlewares, a:middleware)
endfunction

function! s:remove_middleware(...) abort dict
  if a:0 == 0
    let self.middlewares = []
  else
    let index = index(self.middlewares, a:1)
    if index != -1
      call remove(self.middlewares, index)
    endif
  endif
endfunction

function! s:emit(name, ...) abort dict
  let attrs = copy(a:000)
  let listeners = copy(get(self.listeners, a:name, []))
  let middlewares = map(self.middlewares, 'extend(copy(s:middleware), v:val)')
  for middleware in middlewares
    call call(middleware.on_emit_pre, [a:name, listeners, attrs], middleware)
  endfor
  for [Listener, instance] in listeners
    if empty(instance)
      call call(Listener, attrs)
    else
      call call(Listener, attrs, instance)
    endif
  endfor
  for middleware in middlewares
    call call(middleware.on_emit_post, [a:name, listeners, attrs], middleware)
  endfor
endfunction


" Middleware skeleton --------------------------------------------------------
let s:middleware = {}

function! s:middleware.on_emit_pre(name, listeners, attrs) abort
  " Users can override this method
endfunction

function! s:middleware.on_emit_post(name, listeners, attrs) abort
  " Users can override this method
endfunction
