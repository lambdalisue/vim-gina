let s:Argument = vital#gina#import('Argument')
let s:Config = vital#gina#import('Config')
let s:Guard = vital#gina#import('Vim.Guard')
let s:Job = vital#gina#import('System.Job')
let s:Path = vital#gina#import('System.Filepath')
let s:String = vital#gina#import('Data.String')
let s:t_dict = type({})
let s:no_askpass_commands = [
      \ 'config',
      \]
let s:runnings = {}


function! gina#process#runnings() abort
  return values(s:runnings)
endfunction

function! gina#process#register(job) abort
  let s:runnings[a:job.id()] = a:job
endfunction

function! gina#process#unregister(job) abort
  silent! unlet s:runnings[a:job.id()]
endfunction

function! gina#process#wait() abort
  "let timeout = get(a:000, 0, v:null)
  let timeout = get(a:000, 0, 1000)
  let timeout = timeout is# v:null ? v:null : timeout / 1000.0
  let start_time = reltime()
  let updatetime = g:gina#process#updatetime . 'm'
  while timeout is# v:null || timeout > reltimefloat(reltime(start_time))
    if empty(s:runnings)
      return
    endif
    execute 'sleep' updatetime
  endwhile
  cal themis#log(gina#process#runnings())
  return -1
endfunction

function! gina#process#open(git, args, ...) abort
  let args = type(a:args) == s:t_dict ? a:args : s:Argument.new(a:args)
  let pipe = extend(copy(s:pipe), get(a:000, 0, {}))
  let pipe.params = get(args, 'params', {})
  let pipe.params.scheme = get(pipe.params, 'scheme', args.get(0, ''))
  let job = s:Job.start(s:build_raw_args(a:git, args), pipe)
  call job.on_start(job.__job, '', 'on_start')
  call gina#core#console#debug(printf('process: %s', join(job.args)))
  return job
endfunction

function! gina#process#call(git, args, ...) abort
  let options = extend({
        \ 'timeout': v:null,
        \}, get(a:000, 0, {})
        \)
  let pipe = gina#process#pipe#stack#new()
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
  let pipe = gina#process#pipe#buffer#new()
  let job = gina#process#open(a:git, a:args, pipe)
  return job
endfunction

function! gina#process#inform(result) abort
  redraw | echo
  if a:result.status
    call gina#core#console#warn('Fail: ' . join(a:result.args))
  endif
  call gina#core#console#echo(s:String.remove_ansi_sequences(
        \ join(a:result.content, "\n"))
        \)
endfunction

function! gina#process#error(result) abort
  return gina#core#exception#error(printf(
        \ "Fail: %s\n%s",
        \ join(a:result.args),
        \ join(a:result.content, "\n")
        \))
endfunction


" Private --------------------------------------------------------------------
function! s:build_raw_args(git, args) abort
  let args = s:Argument.parse(g:gina#process#command)
  if !empty(a:git) && isdirectory(a:git.worktree)
    call extend(args, ['-C', a:git.worktree])
  endif
  call extend(args, a:args.raw)
  call filter(map(args, 's:expand(v:val)'), '!empty(v:val)')
  " Assign env GIT_TERMINAL_PROMPT/GIT_ASKPASS if necessary
  if index(s:no_askpass_commands, a:args.get(0)) == -1
    call gina#core#askpass#wrap(a:git, args)
  endif
  return args
endfunction

function! s:expand(value) abort
  if a:value =~# '^\%([%#]\|<\w\+>\)\%(:[p8~.htreS]\|:g\?s?\S\+?\S\+?\)*$'
    return gina#core#path#expand(a:value)
  endif
  return a:value
endfunction


" Pipe -----------------------------------------------------------------------
let s:pipe = {}

function! s:pipe.on_start(job, msg, event) abort
  call gina#process#register(self)
endfunction

function! s:pipe.on_exit(job, msg, event) abort
  call gina#process#unregister(self)
endfunction


call s:Config.define('gina#process', {
      \ 'command': 'git --no-pager -c core.editor=false',
      \ 'updatetime': 10,
      \})
