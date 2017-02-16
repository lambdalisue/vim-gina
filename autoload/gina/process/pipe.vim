" Store pipe -----------------------------------------------------------------
function! gina#process#pipe#store() abort
  let pipe = copy(s:store_pipe)
  let pipe._stdout = []
  let pipe._stderr = []
  let pipe._content = []
  return pipe
endfunction

let s:store_pipe = {}

function! s:store_pipe.on_stdout(job, msg, event) abort
  let leading = get(self._content, -1, '')
  silent! call remove(self._content, -1)
  call extend(self._content, [leading . get(a:msg, 0, '')] + a:msg[1:])

  let leading = get(self._stdout, -1, '')
  silent! call remove(self._stdout, -1)
  call extend(self._stdout, [leading . get(a:msg, 0, '')] + a:msg[1:])
endfunction

function! s:store_pipe.on_stderr(job, msg, event) abort
  let leading = get(self._content, -1, '')
  silent! call remove(self._content, -1)
  call extend(self._content, [leading . get(a:msg, 0, '')] + a:msg[1:])

  let leading = get(self._stderr, -1, '')
  silent! call remove(self._stderr, -1)
  call extend(self._stderr, [leading . get(a:msg, 0, '')] + a:msg[1:])
endfunction

function! s:store_pipe.on_exit(job, msg, event) abort
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


" Echo pipe ------------------------------------------------------------------
function! gina#process#pipe#echo() abort
  let pipe = extend(gina#process#pipe#store(), s:echo_pipe)
  return pipe
endfunction

let s:echo_pipe = {}

function! s:echo_pipe.on_exit(job, msg, event) abort
  call gina#core#console#echo(join(self._content, "\n"))
  call gina#core#emitter#emit(
        \ 'command:called:raw',
        \ self.params.scheme,
        \ self.args,
        \ a:msg,
        \)
  call gina#process#unregister(self)
endfunction


" Stream pipe ----------------------------------------------------------------
function! gina#process#pipe#stream() abort
  let pipe = copy(s:stream_pipe)
  let pipe.writer = gina#core#writer#new(s:stream_pipe_writer)
  return pipe
endfunction

let s:stream_pipe = {}
let s:stream_pipe_writer = {}

function! s:stream_pipe.on_start(job, msg, event) abort
  " DO NOT call gina#proceiss#register() here
  let self.writer._job = self
  call self.writer.start()
endfunction

function! s:stream_pipe.on_stdout(job, msg, event) abort
  call self.writer.write(a:msg)
endfunction

function! s:stream_pipe.on_stderr(job, msg, event) abort
  call self.on_stdout(a:job, a:msg, a:event)
endfunction

function! s:stream_pipe.on_exit(job, msg, event) abort
  " DO NOT call gina#proceiss#unregister() here
endfunction

function! s:stream_pipe_writer.on_start() abort
  call gina#process#register(self._job)
endfunction

function! s:stream_pipe_writer.on_stop() abort
  call self._job.stop()
  call gina#core#emitter#emit('command:called', self._job.params.scheme)
  call gina#process#unregister(self._job)
endfunction

function! s:stream_pipe_writer.on_check() abort
  return self._job.status() ==# 'run'
endfunction
