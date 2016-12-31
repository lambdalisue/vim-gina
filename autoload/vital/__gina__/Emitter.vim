let s:listeners = {}
let s:block_count = 0


function! s:emit(name, ...) abort
  if s:is_blocked()
    return
  endif
  let listeners = get(s:listeners, a:name, [])
  for [Listener, instance] in listeners
    if empty(instance)
      call call(Listener, a:000)
    else
      call call(Listener, a:000, instance)
    endif
  endfor
endfunction

function! s:subscribe(name, listener, ...) abort
  let instance = get(a:000, 0, v:null)
  let s:listeners[a:name] = get(s:listeners, a:name, [])
  call add(s:listeners[a:name], [a:listener, instance])
endfunction

function! s:block_start() abort
  let s:block_count += 1
endfunction

function! s:block_end() abort
  let s:block_count -= 1
  let s:block_count = s:block_count < 0 ? 0 : s:block_count
endfunction

function! s:is_blocked() abort
  return s:block_count > 0
endfunction
