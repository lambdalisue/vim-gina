let s:listeners = {}


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

function! s:emit(name, ...) abort
  let listeners = get(s:listeners, a:name, [])
  let listeners += get(s:listeners, '_', [])
  for [Listener, instance] in listeners
    if empty(instance)
      call call(Listener, a:000)
    else
      call call(Listener, a:000, instance)
    endif
  endfor
endfunction
