" Emitter / Observer ---------------------------------------------------------
let s:Emitter = vital#gina#import('Emitter')
let s:Observer = vital#gina#import('Vim.Buffer.Observer')

function! s:on_BufWritePre() abort
  if empty(&buftype) && !empty(gina#core#get())
    let b:gina_internal_emitter_modified = &modified
  endif
endfunction

function! s:on_BufWritePost() abort
  if exists('b:gina_internal_emitter_modified')
    if b:gina_internal_emitter_modified && !&modified
      call s:Emitter.emit('gina:modified')
    endif
    unlet b:gina_internal_emitter_modified
  endif
endfunction

function! s:modified_listener(...) abort
  call s:Observer.update()
endfunction

augroup gina_internal_util_emitter
  autocmd! *
  autocmd BufWritePre  * call s:on_BufWritePre()
  autocmd BufWritePost * nested call s:on_BufWritePost()
augroup END

call s:Emitter.subscribe(
      \ 'gina:modified',
      \ function('s:modified_listener')
      \)


" Exception ------------------------------------------------------------------
let s:Exception = vital#gina#import('Vim.Exception')

function! s:exception_handler(exception) abort
  let m = matchlist(
        \ a:exception,
        \ '^vital: Git\.Term: ValidationError: \(.*\)',
        \)
  if !empty(m)
    call s:Console.warn(m[1])
    return 1
  endif
  return 0
endfunction

call s:Exception.register(
      \ function('s:exception_handler')
      \)
