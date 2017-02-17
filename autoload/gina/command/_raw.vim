function! gina#command#_raw#call(range, args, mods) abort
  let git = gina#core#get()
  let args = gina#command#parse_args(matchstr(a:args, '^_raw\s\+\zs.*'))
  let pipe = copy(s:pipe)
  return gina#process#open(git, args, pipe)
endfunction

function! gina#command#_raw#complete(arglead, cmdline, cursorpos) abort
  return gina#complete#filename#any(a:arglead, a:cmdline, a:cursorpos)
endfunction


" Pipe -----------------------------------------------------------------------
let s:pipe_super = gina#process#pipe#echo()
let s:pipe = deepcopy(s:pipe_super)

function! s:pipe.on_exit(job, msg, event) abort
  call call(s:pipe_super.on_exit, [a:job, a:msg, a:event], self)
  call gina#core#emitter#emit(
        \ 'command:called:raw',
        \ self.params.scheme,
        \)
endfunction
