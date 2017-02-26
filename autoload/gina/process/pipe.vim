let s:Guard = vital#gina#import('Vim.Guard')
let s:Queue = vital#gina#import('Data.Queue')


" Default pipe ---------------------------------------------------------------
function! gina#process#pipe#default() abort
  let pipe = copy(s:default_pipe)
  return pipe
endfunction

let s:default_pipe = {}

function! s:default_pipe.on_start(job, msg, event) abort
  call gina#process#register(self)
endfunction

function! s:default_pipe.on_exit(job, msg, event) abort
  call gina#process#unregister(self)
endfunction



" Store pipe -----------------------------------------------------------------
function! gina#process#pipe#store() abort
  let pipe = extend(gina#process#pipe#default(), s:store_pipe)
  let pipe._stdout = []
  let pipe._stderr = []
  let pipe._content = []
  return pipe
endfunction

let s:store_pipe = gina#util#inherit(s:default_pipe)

function! s:store_pipe.on_stdout(job, msg, event) abort
  call gina#util#extend_content(self._stdout, a:msg)
  call gina#util#extend_content(self._content, a:msg)
endfunction

function! s:store_pipe.on_stderr(job, msg, event) abort
  call gina#util#extend_content(self._stderr, a:msg)
  call gina#util#extend_content(self._content, a:msg)
endfunction

function! s:store_pipe.on_exit(job, msg, event) abort
  if empty(get(self._content, -1, 'a'))
    call remove(self._content, -1)
  endif
  if empty(get(self._stdout, -1, 'a'))
    call remove(self._stdout, -1)
  endif
  if empty(get(self._stderr, -1, 'a'))
    call remove(self._stderr, -1)
  endif
  call self.super(s:store_pipe, 'on_exit', a:job, a:msg, a:event)
endfunction


" Echo pipe ------------------------------------------------------------------
function! gina#process#pipe#echo() abort
  let pipe = extend(gina#process#pipe#store(), s:echo_pipe)
  return pipe
endfunction

let s:echo_pipe = gina#util#inherit(s:store_pipe)

function! s:echo_pipe.on_exit(job, msg, event) abort
  if len(self._content)
    call gina#core#console#message(join(self._content, "\n"))
  endif
  call self.super(s:echo_pipe, 'on_exit', a:job, a:msg, a:event)
endfunction


" Stream pipe ----------------------------------------------------------------
function! gina#process#pipe#stream() abort
  let pipe = extend(gina#process#pipe#echo(), s:stream_pipe)
  let pipe.writer = gina#core#writer#new(s:stream_pipe_writer)
  return pipe
endfunction

function! gina#process#pipe#stream_writer() abort
  return copy(s:stream_pipe_writer)
endfunction

let s:stream_pipe = gina#util#inherit(s:echo_pipe)
let s:stream_pipe_writer = {}

function! s:stream_pipe.on_start(job, msg, event) abort
  call self.super(s:stream_pipe, 'on_start', a:job, a:msg, a:event)
  let self.writer._job = self
  call self.writer.start()
endfunction

function! s:stream_pipe.on_stdout(job, msg, event) abort
  call self.writer.write(a:msg)
endfunction

function! s:stream_pipe.on_exit(job, msg, event) abort
  call self.super(s:stream_pipe, 'on_exit', a:job, a:msg, a:event)
  call self.writer.stop()
endfunction

function! s:stream_pipe_writer.on_start() abort
  let self._winview = getbufvar(self.bufnr, 'gina_winview', [])
  call gina#process#register('writer:' . self.bufnr, 1)
  call gina#core#emitter#emit('writer:started', self.bufnr)
endfunction

function! s:stream_pipe_writer.on_write(msg) abort
  call gina#core#emitter#emit('writer:wrote', self.bufnr, a:msg)
endfunction

function! s:stream_pipe_writer.on_flush(msg) abort
  call gina#core#emitter#emit('writer:flushed', self.bufnr, a:msg)
endfunction

function! s:stream_pipe_writer.on_stop() abort
  call self._job.stop()

  let focus = gina#core#buffer#focus(self.bufnr)
  if empty(focus) || bufnr('%') != self.bufnr
    call gina#core#emitter#emit('writer:stopped', self.bufnr)
    call gina#process#unregister('writer:' . self.bufnr, 1)
    return
  endif
  let guard = s:Guard.store(['&l:modifiable'])
  try
    setlocal modifiable
    if empty(getline('$'))
      silent $delete _
    endif
    setlocal nomodified
  finally
    if !empty(self._winview)
      silent! call winrestview(self._winview)
    endif
    call guard.restore()
    call focus.restore()
    call gina#core#emitter#emit('writer:stopped', self.bufnr)
    call gina#process#unregister('writer:' . self.bufnr, 1)
  endtry
endfunction


" Automatically update b:gina_winview with cursor move while no buffer content
" is available in BufReadCmd and winsaveview() always returns unwilling value
augroup gina_process_pipe_internal
  autocmd! *
  autocmd CursorMoved  gina://* let b:gina_winview = winsaveview()
  autocmd CursorMovedI gina://* let b:gina_winview = winsaveview()
augroup END
