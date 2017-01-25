let s:Emitter = vital#gina#import('Emitter')
let s:Observer = vital#gina#import('Vim.Buffer.Observer')


function! gina#core#emitter#emit(name, ...) abort
  call call(s:Emitter.emit, [a:name] + a:000, s:Emitter)
endfunction

function! gina#core#emitter#subscribe(name, listener, ...) abort
  call call(s:Emitter.subscribe, [a:name, a:listener] + a:000, s:Emitter)
endfunction

function! gina#core#emitter#unsubscribe(name, listener, ...) abort
  call call(s:Emitter.unsubscribe, [a:name, a:listener] + a:000, s:Emitter)
endfunction


" Subscribe ------------------------------------------------------------------
function! s:on_modified() abort
  call s:Observer.update()
endfunction

function! s:on_command_called_raw(scheme) abort
  call gina#core#emitter#emit('modified')
endfunction

call gina#core#emitter#subscribe(
      \ 'modified',
      \ function('s:on_modified')
      \)

call gina#core#emitter#subscribe(
      \ 'command:called:raw',
      \ function('s:on_command_called_raw')
      \)


" Emit 'modified' when a file content is modified ----------------------------
function! s:on_BufWritePre() abort
  if empty(&buftype) && !empty(gina#core#get())
    let b:gina_internal_emitter_modified = &modified
  endif
endfunction

function! s:on_BufWritePost() abort
  if exists('b:gina_internal_emitter_modified')
    if b:gina_internal_emitter_modified && !&modified
      call gina#core#emitter#emit('modified')
    endif
    unlet b:gina_internal_emitter_modified
  endif
endfunction

augroup gina_internal_util_emitter
  autocmd! *
  autocmd BufWritePre  * call s:on_BufWritePre()
  autocmd BufWritePost * nested call s:on_BufWritePost()
augroup END
