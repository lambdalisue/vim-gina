let s:Argument = vital#gina#import('Argument')
let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Config = vital#gina#import('Config')
let s:Console = vital#gina#import('Vim.Console')
let s:Exception = vital#gina#import('Vim.Exception')
let s:Guard = vital#gina#import('Vim.Guard')
let s:Job = vital#gina#import('System.Job')


function! gina#util#process#inform(result) abort
  redraw | echo
  if a:result.status
    call s:Console.warn('Fail: ' . join(a:result.args))
  endif
  for line in a:result.content
    echo line
  endfor
endfunction

function! gina#util#process#error(result) abort
  return s:Exception.error(printf(
        \ "Fail: %s\n%s",
        \ join(a:result.args),
        \ join(a:result.content, "\n")
        \))
endfunction

function! gina#util#process#open(git, args, ...) abort
  let options = get(a:000, 0, {})
  let args = s:build_args(a:git, a:args)
  call s:Console.debug(printf('process: %s', join(args.raw)))
  return s:Job.start(args.raw, options)
endfunction

function! gina#util#process#call(git, args, ...) abort
  let options = extend({
        \ 'on_stdout': v:null,
        \ 'on_stderr': v:null,
        \}, get(a:000, 0, {})
        \)
  let stream = extend(copy(options), s:stream)
  let stream.stdout = []
  let stream.stderr = []
  let stream.content = []
  let stream._stream_on_stdout = options.on_stdout
  let stream._stream_on_stderr = options.on_stderr
  let job = gina#util#process#open(a:git, a:args, stream)
  let status = job.wait()
  return {
        \ 'args': job.args,
        \ 'status': status,
        \ 'stdout': stream.stdout,
        \ 'stderr': stream.stderr,
        \ 'content': stream.content,
        \}
endfunction

function! gina#util#process#pipe_to(bufnr, git, args, ...) abort
  let options = extend({
        \ 'on_stdout': v:null,
        \ 'on_stderr': v:null,
        \ 'on_exit': v:null,
        \}, get(a:000, 0, {})
        \)
  let pipe = extend(copy(options), s:pipe)
  let pipe.bufnr = a:bufnr
  let pipe._pipe_on_stdout = options.on_stdout
  let pipe._pipe_on_stderr = options.on_stderr
  let pipe._pipe_on_exit = options.on_exit
  return gina#util#process#open(a:git, a:args, pipe)
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, extra) abort
  let args = s:Argument.new(g:gina#util#process#command)
  if !empty(a:git) && isdirectory(a:git.worktree)
    call extend(args.raw, ['-C', a:git.worktree])
  endif
  let extra = s:Argument.new(a:extra)
  call extra.map_p(function('s:expand_percent'))
  call extra.map_r(function('s:expand_percent'))
  call extend(args.raw, filter(extra.raw, '!empty(v:val)'))
  return args
endfunction

function! s:expand_percent(value) abort
  return a:value ==# '%'
        \ ? gina#path#expand(a:value)
        \ : a:value
endfunction


" Pipe -----------------------------------------------------------------------
let s:pipe = {}

function! s:assign_content(bufnr, msg) abort
  let focus = gina#util#buffer#focus(a:bufnr)
  if !empty(focus)
    let guard = s:Guard.store(['&l:modifiable'])
    let view = winsaveview()
    try
      setlocal modifiable
      let leading = getline('$')
      let content = [leading . get(a:msg, 0, '')] + a:msg[1:]
      silent lockmarks keepjumps $delete _
      silent lockmarks call s:Buffer.read_content(content, {
            \ 'edit': 1,
            \})
      if empty(getline(1))
        silent lockmarks keepjumps 1delete _
      endif
    finally
      call winrestview(view)
      call guard.restore()
      call focus.restore()
    endtry
  endif
endfunction

function! s:pipe.on_stdout(job, msg, event) abort dict
  call s:assign_content(self.bufnr, a:msg)
  if self._pipe_on_stdout isnot v:null
    call self._pipe_on_stdout(a:job, a:msg, a:event)
  endif
endfunction

function! s:pipe.on_stderr(job, msg, event) abort dict
  call s:assign_content(self.bufnr, a:msg)
  if self._pipe_on_stderr isnot v:null
    call self._pipe_on_stderr(a:job, a:msg, a:event)
  endif
endfunction

function! s:pipe.on_exit(job, msg, event) abort dict
  let focus = gina#util#buffer#focus(self.bufnr)
  if !empty(focus)
    let guard = s:Guard.store(['&l:modifiable'])
    let view = winsaveview()
    try
      setlocal modifiable
      if empty(getline('$'))
        silent lockmarks keepjumps $delete _
      endif
    finally
      call winrestview(view)
      call guard.restore()
      call focus.restore()
    endtry
  endif
  if self._pipe_on_exit isnot v:null
    call self._pipe_on_exit(a:job, a:msg, a:event)
  endif
endfunction


" Stream ---------------------------------------------------------------------
let s:stream = {}

function! s:stream.on_stdout(job, msg, event) abort
  let leading = get(self.stdout, -1, '')
  silent! call remove(self.stdout, -1)
  call extend(self.stdout, [leading . get(a:msg, 0, '')] + a:msg[1:])
  let leading = get(self.content, -1, '')
  silent! call remove(self.content, -1)
  call extend(self.content, [leading . get(a:msg, 0, '')] + a:msg[1:])
  if self._stream_on_stdout isnot v:null
    call self._stream_on_stdout(a:job, a:msg, a:event)
  endif
endfunction

function! s:stream.on_stderr(job, msg, event) abort
  let leading = get(self.stderr, -1, '')
  silent! call remove(self.stderr, -1)
  call extend(self.stderr, [leading . get(a:msg, 0, '')] + a:msg[1:])
  let leading = get(self.content, -1, '')
  silent! call remove(self.content, -1)
  call extend(self.content, [leading . get(a:msg, 0, '')] + a:msg[1:])
  if self._stream_on_stderr isnot v:null
    call self._stream_on_stderr(a:job, a:msg, a:event)
  endif
endfunction

function! s:stream.on_exit(job, msg, event) abort
  if empty(get(self.stdout, -1, ''))
    silent! call remove(self.stdout, -1)
  endif
  if empty(get(self.stderr, -1, ''))
    silent! call remove(self.stderr, -1)
  endif
  if empty(get(self.content, -1, ''))
    silent! call remove(self.content, -1)
  endif
endfunction


" Config ---------------------------------------------------------------------
call s:Config.define('gina#util#process', {
      \ 'command': 'git --no-pager -c core.editor=false',
      \})
