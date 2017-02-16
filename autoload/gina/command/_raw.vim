function! gina#command#_raw#call(range, args, mods) abort
  let git = gina#core#get()
  let args = gina#command#parse_args(matchstr(a:args, '^_raw\s\+\zs.*'))
  let options = copy(s:stream)
  let options.params = args.params
  let options.content = []
  let job = gina#core#process#open(git, args, options)
  return job
endfunction

function! gina#command#_raw#complete(arglead, cmdline, cursorpos) abort
  return gina#complete#filename#any(a:arglead, a:cmdline, a:cursorpos)
endfunction


" Stream instance ------------------------------------------------------------
let s:stream = {}

function! s:stream.on_stdout(job, msg, event) abort
  let leading = get(self.content, -1, '')
  silent! call remove(self.content, -1)
  call extend(self.content, [leading . get(a:msg, 0, '')] + a:msg[1:])
endfunction

function! s:stream.on_stderr(job, msg, event) abort
  let leading = get(self.content, -1, '')
  silent! call remove(self.content, -1)
  call extend(self.content, [leading . get(a:msg, 0, '')] + a:msg[1:])
endfunction

function! s:stream.on_exit(job, msg, event) abort
  call gina#core#console#echo(join(self.content, "\n"))
  call gina#core#emitter#emit(
        \ 'command:called:raw',
        \ self.params.scheme,
        \ self.args,
        \ a:msg,
        \)
endfunction
