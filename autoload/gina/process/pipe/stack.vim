function! gina#process#pipe#stack#new() abort
  return deepcopy(s:pipe)
endfunction


" Pipe  ----------------------------------------------------------------------
let s:pipe = {'_stdout': [], '_stderr': [], '_content': []}

function! s:pipe.on_stdout(job, msg, event) abort
  let leading = get(self._content, -1, '')
  silent! call remove(self._content, -1)
  call extend(self._content, [leading . get(a:msg, 0, '')] + a:msg[1:])

  let leading = get(self._stdout, -1, '')
  silent! call remove(self._stdout, -1)
  call extend(self._stdout, [leading . get(a:msg, 0, '')] + a:msg[1:])
endfunction

function! s:pipe.on_stderr(job, msg, event) abort
  let leading = get(self._content, -1, '')
  silent! call remove(self._content, -1)
  call extend(self._content, [leading . get(a:msg, 0, '')] + a:msg[1:])

  let leading = get(self._stderr, -1, '')
  silent! call remove(self._stderr, -1)
  call extend(self._stderr, [leading . get(a:msg, 0, '')] + a:msg[1:])
endfunction

function! s:pipe.on_exit(job, msg, event) abort
  if empty(get(self._content, -1, ''))
    silent! call remove(self._content, -1)
  endif
  if empty(get(self._stdout, -1, ''))
    silent! call remove(self._stdout, -1)
  endif
  if empty(get(self._stderr, -1, ''))
    silent! call remove(self._stderr, -1)
  endif
  call gina#process#unregister(self)
endfunction
