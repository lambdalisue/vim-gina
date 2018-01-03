let s:Guard = vital#gina#import('Vim.Guard')
let s:Queue = vital#gina#import('Data.Queue')
let s:String = vital#gina#import('Data.String')

function! s:extend_content(content, data) abort
  unlockvar 1 a:content
  let a:content[-1] .= a:data[0]
  call extend(a:content, a:data[1:])
  lockvar 1 a:content
endfunction


" Default pipe -------------------------------------------------------------
function! gina#process#pipe#default() abort
  let pipe = deepcopy(s:default_pipe)
  return pipe
endfunction

function! s:_default_pipe_on_start() abort dict
  call gina#process#register(self)
endfunction

function! s:_default_pipe_on_exit(data) abort dict
  call gina#process#unregister(self)
endfunction

let s:default_pipe = {
      \ 'on_start': function('s:_default_pipe_on_start'),
      \ 'on_exit': function('s:_default_pipe_on_exit'),
      \}


" Store pipe ---------------------------------------------------------------
function! gina#process#pipe#store() abort
  let pipe = deepcopy(s:store_pipe)
  let pipe.stdout = ['']
  let pipe.stderr = ['']
  let pipe.content = ['']
  lockvar 1 pipe.stdout
  lockvar 1 pipe.stderr
  lockvar 1 pipe.content
  return pipe
endfunction

function! s:_store_pipe_on_receive(event, data) abort dict
  call map(a:data, 'v:val[-1:] ==# "\r" ? v:val[:-2] : v:val')
  call s:extend_content(self[a:event], a:data)
  call s:extend_content(self.content, a:data)
endfunction

let s:store_pipe = {
      \ 'on_start': function('s:_default_pipe_on_start'),
      \ 'on_stdout': function('s:_store_pipe_on_receive', ['stdout']),
      \ 'on_stderr': function('s:_store_pipe_on_receive', ['stderr']),
      \ 'on_exit': function('s:_default_pipe_on_exit'),
      \}


" Echo pipe ----------------------------------------------------------------
function! gina#process#pipe#echo() abort
  let pipe = deepcopy(s:echo_pipe)
  let pipe.stdout = ['']
  let pipe.stderr = ['']
  let pipe.content = ['']
  lockvar 1 pipe.stdout
  lockvar 1 pipe.stderr
  lockvar 1 pipe.content
  return pipe
endfunction

function! s:_echo_pipe_on_exit(data) abort dict
  call call('s:_default_pipe_on_exit', [a:data], self)
  if len(self.content)
    call gina#core#console#message(
          \ s:String.remove_ansi_sequences(join(self.content, "\n")),
          \)
  endif
endfunction

let s:echo_pipe = {
      \ 'on_start': function('s:_default_pipe_on_start'),
      \ 'on_stdout': function('s:_store_pipe_on_receive', ['stdout']),
      \ 'on_stderr': function('s:_store_pipe_on_receive', ['stderr']),
      \ 'on_exit': function('s:_echo_pipe_on_exit'),
      \}


" Stream pipe --------------------------------------------------------------
function! gina#process#pipe#stream(...) abort
  let pipe = deepcopy(s:stream_pipe)
  let pipe.writer = gina#core#writer#new(a:0 ? a:1 : s:stream_pipe_writer)
  let pipe.stderr = ['']
  let pipe.content = ['']
  lockvar 1 pipe.stderr
  lockvar 1 pipe.content
  return pipe
endfunction

function! s:_stream_pipe_on_start() abort dict
  call call('s:_default_pipe_on_start', [], self)
  let self.writer._job = self
  call self.writer.start()
endfunction

function! s:_stream_pipe_on_receive(data) abort dict
  call map(a:data, 'v:val[-1:] ==# "\r" ? v:val[:-2] : v:val')
  call self.writer.write(a:data)
endfunction

function! s:_stream_pipe_on_exit(data) abort dict
  call self.writer.stop()
  call call('s:_echo_pipe_on_exit', [a:data], self)
endfunction

let s:stream_pipe = {
      \ 'on_start': function('s:_stream_pipe_on_start'),
      \ 'on_stdout': function('s:_stream_pipe_on_receive'),
      \ 'on_stderr': function('s:_store_pipe_on_receive', ['stderr']),
      \ 'on_exit': function('s:_stream_pipe_on_exit'),
      \}

" Stream pipe writer -------------------------------------------------------
function! gina#process#pipe#stream_writer() abort
  return deepcopy(s:stream_pipe_writer)
endfunction

function! s:_stream_pipe_writer_on_start() abort dict
  let self._winview = getbufvar(self.bufnr, 'gina_winview', [])
  let self._spinner = gina#core#spinner#start(self.bufnr)
  call gina#process#register('writer:' . self.bufnr, 1)
  call gina#core#emitter#emit('writer:started', self.bufnr)
endfunction

function! s:_stream_pipe_writer_on_write(msg) abort dict
  call gina#core#emitter#emit('writer:wrote', self.bufnr, a:msg)
endfunction

function! s:_stream_pipe_writer_on_flush(msg) abort dict
  call gina#core#emitter#emit('writer:flushed', self.bufnr, a:msg)
endfunction

function! s:_stream_pipe_writer_on_stop() abort dict
  call self._job.stop()
  call self._spinner.stop()

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

let s:stream_pipe_writer = {
      \ 'on_start': function('s:_stream_pipe_writer_on_start'),
      \ 'on_write': function('s:_stream_pipe_writer_on_write'),
      \ 'on_flush': function('s:_stream_pipe_writer_on_flush'),
      \ 'on_stop': function('s:_stream_pipe_writer_on_stop'),
      \}


" Automatically update b:gina_winview with cursor move while no buffer content
" is available in BufReadCmd and winsaveview() always returns unwilling value
augroup gina_process_pipe_internal
  autocmd! *
  autocmd BufEnter  gina://* let b:gina_winview = winsaveview()
  autocmd CursorMoved  gina://* let b:gina_winview = winsaveview()
  autocmd CursorMovedI gina://* let b:gina_winview = winsaveview()
augroup END
