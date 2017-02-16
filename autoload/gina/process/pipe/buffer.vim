let s:Guard = vital#gina#import('Vim.Guard')
let s:Queue = vital#gina#import('Data.Queue')
let s:writer_timer = {}


function! gina#process#pipe#buffer#new() abort
  let pipe = copy(s:pipe)
  let pipe.writer = copy(s:writer)
  let pipe.writer._bufnr = bufnr('%')
  let pipe.writer._queue = s:Queue.new()
  let pipe.writer._winview = get(b:, 'gina_winview', winsaveview())
  return pipe
endfunction


" Pipe -----------------------------------------------------------------------
let s:pipe = {}

function! s:pipe.on_start(job, msg, event) abort
  call gina#process#register(self)
  let self.writer._job = self
  let self.writer._timer = timer_start(
        \ g:gina#process#updatetime,
        \ function('s:timer_callback'),
        \ {'repeat': -1}
        \)
  let s:writer_timer[self.writer._timer] = self.writer
  let guard = s:Guard.store(['&l:modifiable'])
  try
    setlocal modifiable
    silent lockmarks keepjumps %delete _
  finally
    call guard.restore()
  endtry
endfunction

function! s:pipe.on_stdout(job, msg, event) abort
  call self.writer.write(a:msg)
endfunction

function! s:pipe.on_stderr(job, msg, event) abort
  call self.on_stdout(a:job, a:msg, a:event)
endfunction

function! s:pipe.on_exit(job, msg, event) abort
  " NOTE: call gina#proceiss#register() in writer.close()
endfunction


" Writer ---------------------------------------------------------------------
let s:writer = {'_timer': v:null}

function! s:writer.write(msg) abort
  call self._queue.put(a:msg)
endfunction

function! s:writer.flush() abort
  let msg = self._queue.get()
  if msg is# v:null
    if self._job.status() ==# 'dead'
      call self.close()
    endif
    return
  endif
  let focus = gina#core#buffer#focus(self._bufnr)
  if empty(focus) || bufnr('%') != self._bufnr
    return self.close()
  endif
  let guard = s:Guard.store(['&l:modifiable'])
  let view = winsaveview()
  try
    setlocal modifiable
    call gina#core#buffer#extend_content(msg)
  finally
    call winrestview(view)
    call guard.restore()
    call focus.restore()
  endtry
endfunction

function! s:writer.close() abort
  silent! unlet s:writer_timer[self._timer]
  silent! call timer_stop(self._timer)
  silent! call self._job.stop()
  let focus = gina#core#buffer#focus(self._bufnr)
  if empty(focus) || bufnr('%') != self._bufnr
    call gina#core#emitter#emit('command:called', self._job.params.scheme)
    call gina#process#unregister(self._job)
    return
  endif
  let guard = s:Guard.store(['&l:modifiable'])
  try
    setlocal modifiable
    if empty(getline('$'))
      silent lockmarks keepjumps $delete _
    endif
    setlocal nomodified
  finally
    call winrestview(self._winview)
    call guard.restore()
    call focus.restore()
    call gina#core#emitter#emit('command:called', self._job.params.scheme)
    call gina#process#unregister(self._job)
  endtry
endfunction

function! s:timer_callback(timer) abort
  let writer = get(s:writer_timer, a:timer, v:null)
  if writer is# v:null
    call timer_stop(a:timer)
    return
  endif
  call writer.flush()
endfunction


" Automatically update b:gina_winview with cursor move while no buffer content
" is available in BufReadCmd and winsaveview() always returns unwilling value
augroup gina_process_pipe_buffer_internal
  autocmd! *
  autocmd CursorMoved  gina://* let b:gina_winview = winsaveview()
  autocmd CursorMovedI gina://* let b:gina_winview = winsaveview()
augroup END
