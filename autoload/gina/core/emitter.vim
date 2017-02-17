let s:Emitter = vital#gina#import('Emitter')
let s:Observer = vital#gina#import('Vim.Buffer.Observer')

let s:modified_timer = v:null

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
function! s:on_modified(...) abort
  call s:Observer.update()
endfunction

function! s:on_modified_delay() abort
  if s:modified_timer isnot# v:null
    " Do not emit 'modified' for previous 'modified:delay'
    silent! call timer_stop(s:modified_timer)
  endif
  let s:modified_timer = timer_start(
        \ g:gina#core#emitter#modified_delay,
        \ function('s:emit_modified')
        \)
endfunction

function! s:on_command_called_raw(...) abort
  call gina#core#emitter#emit('modified:delay')
endfunction

function! s:emit_modified(...) abort
  call gina#core#emitter#emit('modified')
endfunction

if !exists('s:subscribed')
  let s:subscribed = 1
  call gina#core#emitter#subscribe(
        \ 'modified',
        \ function('s:on_modified')
        \)

  call gina#core#emitter#subscribe(
        \ 'modified:delay',
        \ function('s:on_modified_delay')
        \)

  call gina#core#emitter#subscribe(
        \ 'command:called:raw',
        \ function('s:on_command_called_raw')
        \)
endif

" Emit 'modified' when a file content is modified ----------------------------
function! s:on_BufWritePre() abort
  if empty(&buftype) && !empty(gina#core#get())
    let b:gina_internal_emitter_modified = &modified
  endif
endfunction

function! s:on_BufWritePost() abort
  if exists('b:gina_internal_emitter_modified')
    if b:gina_internal_emitter_modified && !&modified
      call gina#core#emitter#emit('modified:delay')
    endif
    unlet b:gina_internal_emitter_modified
  endif
endfunction

augroup gina_internal_util_emitter
  autocmd! *
  autocmd BufWritePre  * call s:on_BufWritePre()
  autocmd BufWritePost * nested call s:on_BufWritePost()
augroup END


call gina#config(expand('<sfile>'), {
      \ 'modified_delay': 10,
      \})
