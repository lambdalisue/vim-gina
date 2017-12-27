function! gina#command#_raw#call(range, args, mods) abort
  let git = gina#core#get()
  let args = s:build_args(git, a:args)
  let pipe = a:mods =~# '\<silent\>'
        \ ? deepcopy(s:pipe_silent)
        \ : deepcopy(s:pipe)
  return gina#process#open(git, args, pipe)
endfunction

function! gina#command#_raw#complete(arglead, cmdline, cursorpos) abort
  return gina#complete#filename#any(a:arglead, a:cmdline, a:cursorpos)
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = a:args.clone()
  if args.get(0) ==# '_raw'
    " Remove leading '_raw' if exists
    call args.pop(0)
  endif
  return args.lock()
endfunction


" Pipe -----------------------------------------------------------------------
let s:pipe = gina#util#inherit(gina#process#pipe#echo())
let s:pipe_silent = gina#util#inherit(gina#process#pipe#default())

function! s:pipe.on_exit(data) abort
  call self.super(s:pipe, 'on_exit', a:data)
  call gina#core#emitter#emit(
        \ 'command:called:raw',
        \ self.params.scheme,
        \)
endfunction

function! s:pipe_silent.on_exit(data) abort
  call self.super(s:pipe_silent, 'on_exit', a:data)
  call gina#core#emitter#emit(
        \ 'command:called:raw',
        \ self.params.scheme,
        \)
endfunction


" Event ----------------------------------------------------------------------
function! s:on_command_called_raw(...) abort
  call gina#core#emitter#emit('modified:delay')
endfunction


if !exists('s:subscribed')
  let s:subscribed = 1
  call gina#core#emitter#subscribe(
        \ 'command:called:raw',
        \ function('s:on_command_called_raw')
        \)
endif
