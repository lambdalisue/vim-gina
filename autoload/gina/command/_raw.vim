function! gina#command#_raw#call(range, args, mods) abort
  let git = gina#core#get()
  let args = s:build_args(git, a:args)
  let pipe = extend(gina#process#pipe#echo(), s:pipe)
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
let s:pipe_super = gina#process#pipe#echo()
let s:pipe = {}

function! s:pipe.on_exit(job, msg, event) abort
  call call(s:pipe_super.on_exit, [a:job, a:msg, a:event], self)
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
