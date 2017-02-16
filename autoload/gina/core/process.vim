let s:Argument = vital#gina#import('Argument')
let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Config = vital#gina#import('Config')
let s:Guard = vital#gina#import('Vim.Guard')
let s:Job = vital#gina#import('System.Job')
let s:Path = vital#gina#import('System.Filepath')
let s:Queue = vital#gina#import('Data.Queue')
let s:String = vital#gina#import('Data.String')

let s:t_dict = type({})
let s:no_askpass_commands = [
      \ 'config',
      \]
let s:jobs = {}


function! gina#core#process#open(git, args, ...) abort
  let options = get(a:000, 0, {})
  let args = s:build_args(a:git, a:args)
  call gina#core#console#debug(printf('process: %s', join(args.raw)))
  return s:Job.start(args.raw, options)
endfunction

function! gina#core#process#call(git, args, ...) abort
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
  let job = gina#core#process#open(a:git, a:args, pipe)
  let status = job.wait(options.timeout)
  return {
        \ 'args': job.args,
        \ 'status': status,
        \ 'stdout': pipe._stdout,
        \ 'stderr': pipe._stderr,
        \ 'content': pipe._content,
        \}
endfunction

function! gina#core#process#exec(git, args) abort
  let guard = s:Guard.store(['&l:modifiable'])
  try
    setlocal modifiable
    silent lockmarks keepjumps %delete _
  finally
    call guard.restore()
  endtry
  " Start a new process
  let job = gina#core#process#open(a:git, a:args, copy(s:stream))
  let job._args = a:args
  let job._queue = s:Queue.new()
  let job._bufnr = bufnr('%')
  let job._winview = get(b:, 'gina_winview', winsaveview())
  let job._timer = timer_start(
        \ g:gina#core#process#updatetime,
        \ function('s:exec_callback'),
        \ { 'repeat': -1 }
        \)
  let s:jobs[job._timer] = job
  return job
endfunction

function! gina#core#process#wait() abort
  let updatetime = g:gina#core#process#updatetime . 'm'
  while !empty(s:jobs)
    execute 'sleep' updatetime
  endwhile
endfunction

function! gina#core#process#inform(result) abort
  redraw | echo
  if a:result.status
    call gina#core#console#warn('Fail: ' . join(a:result.args))
  endif
  call gina#core#console#echo(s:String.remove_ansi_sequences(
        \ join(a:result.content, "\n"))
        \)
endfunction

function! gina#core#process#error(result) abort
  return gina#core#exception#error(printf(
        \ "Fail: %s\n%s",
        \ join(a:result.args),
        \ join(a:result.content, "\n")
        \))
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, extra) abort
  let args = s:Argument.new(g:gina#core#process#command)
  let extra = type(a:extra) == s:t_dict ? a:extra : s:Argument.new(a:extra)
  if !empty(a:git) && isdirectory(a:git.worktree)
    " NOTE
    " git does not recognize -C{worktree} so "args.set()" could not be used
    let args.raw += ['-C', a:git.worktree]
  endif
  call extend(args.raw, extra.raw)
  call filter(map(args.raw, 's:expand(v:val)'), '!empty(v:val)')
  if index(s:no_askpass_commands, extra.get(0)) == -1
    call gina#core#askpass#wrap(a:git, args.raw)
  endif
  return args
endfunction

function! s:expand(value) abort
  if a:value =~# '^\%([%#]\|<\w\+>\)\%(:[p8~.htreS]\|:g\?s?\S\+?\S\+?\)*$'
    return gina#core#path#expand(a:value)
  endif
  return a:value
endfunction

function! s:exec_callback(timer) abort
  let job = get(s:jobs, a:timer, v:null)
  if job is# v:null
    call timer_stop(a:timer)
    return
  endif
  call job.on_timer()
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


" Stream ---------------------------------------------------------------------
let s:stream = {}

function! s:stream.on_stdout(job, msg, event) abort
  call self._queue.put(a:msg)
endfunction

function! s:stream.on_stderr(job, msg, event) abort
  call self.on_stdout(a:job, a:msg, a:event)
endfunction

function! s:stream.on_timer() abort
  let msg = self._queue.get()
  if msg is# v:null
    if self.status() ==# 'dead'
      call self.close()
    endif
  else
    call self.flush(msg)
  endif
endfunction

function! s:stream.flush(msg) abort
  let focus = gina#core#buffer#focus(self._bufnr)
  if empty(focus) || bufnr('%') != self._bufnr
    return self.close()
  endif
  let guard = s:Guard.store(['&l:modifiable'])
  let view = winsaveview()
  try
    setlocal modifiable
    call gina#core#buffer#extend_content(a:msg)
  finally
    call winrestview(view)
    call guard.restore()
    call focus.restore()
  endtry
endfunction

function! s:stream.close() abort
  let focus = gina#core#buffer#focus(self._bufnr)
  if empty(focus) || bufnr('%') != self._bufnr
    silent! unlet s:jobs[self._timer]
    silent! call timer_stop(self._timer)
    silent! call self.stop()
    call gina#core#emitter#emit('command:called', self._args.params.scheme)
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
    silent! unlet s:jobs[self._timer]
    silent! call timer_stop(self._timer)
    silent! call self.stop()
    call gina#core#emitter#emit('command:called', self._args.params.scheme)
  endtry
endfunction


" Automatically update b:gina_winview with cursor move while no buffer content
" is available in BufReadCmd and winsaveview() always returns unwilling value
augroup gina_core_process_internal
  autocmd! *
  autocmd CursorMoved  gina://* let b:gina_winview = winsaveview()
  autocmd CursorMovedI gina://* let b:gina_winview = winsaveview()
augroup END


call s:Config.define('gina#core#process', {
      \ 'command': 'git --no-pager -c core.editor=false',
      \ 'updatetime': 10,
      \})
