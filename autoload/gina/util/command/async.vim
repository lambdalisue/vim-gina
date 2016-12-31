let s:Emitter = vital#gina#import('Emitter')


" NOTE:
" In BufReadCmd, the content of the buffer is cleared so save winview every
" after cursor has moved and use that to restore winview.
function! gina#util#command#async#attach() abort
  augroup gina_internal_util_command_async
    autocmd! * <buffer>
    autocmd CursorMoved <buffer> let b:gina_winview = winsaveview()
  augroup END
endfunction

function! gina#util#command#async#call(git, args) abort
  let bufnr = bufnr('%')
  " Stop previous job if exists
  if exists('b:gina_job')
    silent! call b:gina_job.stop()
    silent! unlet b:gina_job
  endif
  let b:gina_job = gina#util#process#pipe_to(bufnr, a:git, a:args, {
        \ 'scheme': get(gina#util#path#params('%'), 'scheme', v:null),
        \ 'winview': get(b:, 'gina_winview', {}),
        \ 'on_exit': function('s:on_exit'),
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_exit(job, msg, event) abort dict
  let focus = gina#util#buffer#focus(self.bufnr)
  if empty(focus)
    return
  endif
  try
    silent! unlet b:gina_job
    call winrestview(self.winview)
    call s:Emitter.emit(printf('gina:%s:updated', self.scheme))
  finally
    call focus.restore()
  endtry
endfunction
