let s:Emitter = vital#gina#import('Emitter')
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

function! gina#core#emitter#add_middleware(middleware) abort
  call call(s:Emitter.add_middleware, [a:middleware] + a:000, s:Emitter)
endfunction

function! gina#core#emitter#remove_middleware(...) abort
  call call(s:Emitter.remove_middleware, a:000, s:Emitter)
endfunction


" Subscribe ------------------------------------------------------------------
if has('nvim')
  function! s:on_modified(...) abort
    let winid_saved = win_getid()
    for winnr in range(1, winnr('$'))
      let bufnr = winbufnr(winnr)
      if !getbufvar(bufnr, '&modified')
            \ && getbufvar(bufnr, '&autoread')
            \ && bufname(bufnr) =~# '^gina://'
        keepjumps call win_gotoid(bufwinid(bufnr))
        keepjumps edit
      endif
    endfor
    keepjumps call win_gotoid(winid_saved)
  endfunction
else
  " Issue:
  "
  " The implementation for Vim 8 has two major issues
  "
  " 1. It uses 'BufReadCmd' instead of 'edit'. It is not eqaul to 'edit' which
  "    is often used to update the buffer content in Vim. Using 'BufReadCmd'
  "    directly may affect other plugins which rely on 'edit' related autocmd
  " 2. It calls 'gina#process#wait()' at the end, mean that the function is no
  "    longer asynchronous. This function would affect the Vim's main thread
  "    as like other non-asynchronous plugins does. So heavy processions called
  "    in this function would slow Vim's response.
  "
  " When users hit '<<' on gina-status window in Vim, users may notice that
  " the content of the buffer is wiped out and have to hit ':e' to reload the
  " content. It is not happen in Neovim.
  "
  " I'm not really sure but the issue comes from the following limitations
  "
  " When a parent thread is closed before children threads which were invoked
  " in the parent thread, the buffer handling occurred in children threads
  " fails without any exceptions. So that the parent thread requires to wait
  " the children thread termination. In short, 'gina#process#wait()' is
  " required at the end of the function.
  "
  " Even the parent thread waits children threads, if the children threads is
  " called within autocmd which was invoked by "edit" command, the buffer
  " handling fail and no content appeared on the buffer. In short, BufReadCmd
  " requires to be called WITHOUT using "edit" comman.
  "
  " Let me know if you found a better solution or exact reason why the code
  " for Neovim does not work properly in Vim.
  "
  function! s:on_modified(...) abort
    let winid_saved = win_getid()
    for winnr in range(1, winnr('$'))
      let bufnr = winbufnr(winnr)
      if !getbufvar(bufnr, '&modified')
            \ && getbufvar(bufnr, '&autoread')
            \ && bufname(bufnr) =~# '^gina://'
        keepjumps call win_gotoid(bufwinid(bufnr))
        keepjumps call gina#core#writer#assign_content(bufnr, [])
        keepjumps call gina#util#doautocmd('BufReadCmd')
      endif
    endfor
    keepjumps call win_gotoid(winid_saved)
    call gina#process#wait()
  endfunction
endif

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
