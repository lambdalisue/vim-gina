function! gina#process#pipe#stdout#new() abort
  return extend(gina#process#pipe#stack#new(), s:pipe)
endfunction


" Pipe -----------------------------------------------------------------------
let s:pipe = {}

function! s:pipe.on_exit(job, msg, event) abort
  call gina#core#console#echo(join(self._content, "\n"))
  call gina#core#emitter#emit(
        \ 'command:called:raw',
        \ self.params.scheme,
        \ self.args,
        \ a:msg,
        \)
  call gina#process#unregister(self)
endfunction
