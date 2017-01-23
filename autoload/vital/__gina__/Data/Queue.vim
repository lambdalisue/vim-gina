function! s:new() abort
  let queue = copy(s:queue)
  let queue.__data = []
  return queue
endfunction

let s:queue = {}

function! s:queue.put(data) abort
  call add(self.__data, a:data)
endfunction

function! s:queue.get() abort
  return len(self.__data) ? remove(self.__data, 0) : v:null
endfunction
