let s:Argument = vital#gina#import('Argument')
let s:Config = vital#gina#import('Config')
let s:Console = vital#gina#import('Vim.Console')
let s:Exception = vital#gina#import('Vim.Exception')
let s:Job = vital#gina#import('System.Job')


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
        \ ? gina#util#path#expand(a:value)
        \ : a:value
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


call s:Config.define('gina#process', {
      \ 'command': 'git --no-pager -c core.editor=false',
      \})
