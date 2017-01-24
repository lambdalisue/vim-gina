let s:Argument = vital#gina#import('Argument')
let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Config = vital#gina#import('Config')
let s:Console = vital#gina#import('Vim.Console')
let s:Emitter = vital#gina#import('Emitter')
let s:Exception = vital#gina#import('Vim.Exception')
let s:Guard = vital#gina#import('Vim.Guard')
let s:Job = vital#gina#import('System.Job')
let s:Queue = vital#gina#import('Data.Queue')

let s:t_dict = type({})


function! gina#process#open(git, args, ...) abort
  let options = get(a:000, 0, {})
  let args = s:build_args(a:git, a:args)
  call s:Console.debug(printf('process: %s', join(args.raw)))
  return s:Job.start(args.raw, options)
endfunction

function! gina#process#call(git, args, ...) abort
  let options = extend({
        \ 'on_stdout': v:null,
        \ 'on_stderr': v:null,
        \ 'on_exit': v:null,
        \ 'timeout': v:null,
        \}, get(a:000, 0, {})
        \)
  let pipe = extend(copy(options), s:pipe)
  let pipe._on_stdout = options.on_stdout
  let pipe._on_stderr = options.on_stderr
  let pipe._on_exit = options.on_exit
  let pipe._stdout = []
  let pipe._stderr = []
  let pipe._content = []
  let job = gina#process#open(a:git, a:args, pipe)
  let status = job.wait(options.timeout)
  return {
        \ 'args': job.args,
        \ 'status': status,
        \ 'stdout': pipe._stdout,
        \ 'stderr': pipe._stderr,
        \ 'content': pipe._content,
        \}
endfunction

function! gina#process#exec(git, args) abort
  if get(get(a:args, 'params', {}), 'async')
    call s:exec_async(a:git, a:args)
  else
    call s:exec_sync(a:git, a:args)
  endif
endfunction

function! gina#process#inform(result) abort
  redraw | echo
  if a:result.status
    call s:Console.warn('Fail: ' . join(a:result.args))
  endif
  call s:Console.echo(join(a:result.content, "\n"))
endfunction

function! gina#process#error(result) abort
  return s:Exception.error(printf(
        \ "Fail: %s\n%s",
        \ join(a:result.args),
        \ join(a:result.content, "\n")
        \))
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, extra) abort
  let args = s:Argument.new(g:gina#process#command)
  if !empty(a:git) && isdirectory(a:git.worktree)
    " NOTE
    " git does not recognize -C{worktree} so "args.set()" could not be used
    let args.raw += ['-C', a:git.worktree]
  endif
  call extend(args.raw, type(a:extra) == s:t_dict ? a:extra.raw : a:extra)
  call map(args.raw, 's:expand(v:val)')
  call filter(args.raw, '!empty(v:val)')
  return args
endfunction

function! s:expand(value) abort
  if a:value =~# '^\%([%#]\|<\w\+>\)\%(:[p8~.htreS]\|:g\?s?\S\+?\S\+?\)*$'
    return gina#util#expand(a:value)
  endif
  return a:value
endfunction

function! s:exec_sync(git, args) abort
  let result = gina#process#call(a:git, a:args)
  if result.status
    throw gina#process#error(result)
  endif
  call gina#util#buffer#assign_content(result.content)
  call s:Emitter.emit(printf('gina:%s:done', a:args.get(0)))
endfunction

function! s:exec_async(git, args) abort
  let guard = s:Guard.store(['&l:modifiable'])
  try
    setlocal modifiable
    silent lockmarks keepjumps %delete _
  finally
    call guard.restore()
  endtry
  " Start a new process
  let async_process = gina#process#open(a:git, a:args, copy(s:async_process))
  let async_process._args = a:args
  let async_process._queue = s:Queue.new()
  let async_process._bufnr = bufnr('%')
  let async_process._timer = timer_start(
        \ g:gina#process#updatetime,
        \ 's:async_process_callback',
        \ { 'repeat': -1 }
        \)
  let s:async_processes[async_process._timer] = async_process
  return async_process
endfunction

function! s:async_process_callback(timer) abort
  let async_process = get(s:async_processes, a:timer, v:null)
  if async_process is# v:null
    call timer_stop(a:timer)
    return
  endif
  call async_process.on_timer()
endfunction

" Pipe -----------------------------------------------------------------------
let s:pipe = {}

function! s:pipe.on_stdout(job, msg, event) abort
  let leading = get(self._stdout, -1, '')
  silent! call remove(self._stdout, -1)
  call extend(self._stdout, [leading . get(a:msg, 0, '')] + a:msg[1:])
  let leading = get(self._content, -1, '')
  silent! call remove(self._content, -1)
  call extend(self._content, [leading . get(a:msg, 0, '')] + a:msg[1:])
  if self._on_stdout isnot# v:null
    call self._on_stdout(a:job, a:msg, a:event)
  endif
endfunction

function! s:pipe.on_stderr(job, msg, event) abort
  let leading = get(self._stderr, -1, '')
  silent! call remove(self._stderr, -1)
  call extend(self._stderr, [leading . get(a:msg, 0, '')] + a:msg[1:])
  let leading = get(self._content, -1, '')
  silent! call remove(self._content, -1)
  call extend(self._content, [leading . get(a:msg, 0, '')] + a:msg[1:])
  if self._on_stderr isnot# v:null
    call self._on_stderr(a:job, a:msg, a:event)
  endif
endfunction

function! s:pipe.on_exit(job, msg, event) abort
  if empty(get(self._stdout, -1, ''))
    silent! call remove(self._stdout, -1)
  endif
  if empty(get(self._stderr, -1, ''))
    silent! call remove(self._stderr, -1)
  endif
  if empty(get(self._content, -1, ''))
    silent! call remove(self._content, -1)
  endif
  if self._on_exit isnot# v:null
    call self._on_exit(a:job, a:msg, a:event)
  endif
endfunction


" Async process --------------------------------------------------------------
let s:async_processes = {}
let s:async_process = {}

function! s:async_process.on_stdout(job, msg, event) abort
  call self._queue.put(a:msg)
endfunction

function! s:async_process.on_stderr(job, msg, event) abort
  call self.on_stdout(a:job, a:msg, a:event)
endfunction

function! s:async_process.on_timer() abort
  let msg = self._queue.get()
  if msg is# v:null
    if self.status() ==# 'dead'
      call self.close()
    endif
  else
    call self.flush(msg)
  endif
endfunction

function! s:async_process.flush(msg) abort
  let focus = gina#util#buffer#focus(self._bufnr)
  if empty(focus) || bufnr('%') != self._bufnr
    return self.close()
  endif
  let guard = s:Guard.store(['&l:modifiable'])
  let view = winsaveview()
  try
    setlocal modifiable
    call gina#util#buffer#extend_content(a:msg)
  finally
    call winrestview(view)
    call guard.restore()
    call focus.restore()
  endtry
endfunction

function! s:async_process.close() abort
  silent! unlet s:async_processes[self._timer]
  silent! call timer_stop(self._timer)
  silent! call self.stop()
  let focus = gina#util#buffer#focus(self._bufnr)
  if empty(focus) || bufnr('%') != self._bufnr
    return
  endif
  let guard = s:Guard.store(['&l:modifiable'])
  let view = winsaveview()
  try
    setlocal modifiable
    if empty(getline('$'))
      silent lockmarks keepjumps $delete _
    endif
    setlocal nomodified
    call s:Emitter.emit(printf('gina:%s:async:done', self._args.get(0)))
  finally
    call winrestview(view)
    call guard.restore()
    call focus.restore()
  endtry
endfunction


call s:Config.define('gina#process', {
      \ 'command': 'git --no-pager -c core.editor=false',
      \ 'updatetime': 10,
      \})
