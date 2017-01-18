if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1
let b:undo_ftplugin = join([
      \ 'setlocal winfixheight<',
      \ 'setlocal nolist< nospell<',
      \ 'setlocal nowrap< nofoldenable<',
      \ 'setlocal nonumber< norelativenumber<',
      \ 'setlocal foldcolumn< colorcolumn<',
      \ 'silent! nunmap <buffer> <Return>',
      \], ' | ')

setlocal winfixheight
setlocal nolist nospell
setlocal nowrap nofoldenable
setlocal nonumber norelativenumber
setlocal foldcolumn=0 colorcolumn=0

" Mappings
let params = gina#util#path#params('%')
if empty(get(params, 'commit'))
  call gina#util#nmap('<Return>', '<Plug>(gina-edit)zv')
else
  call gina#util#nmap('<Return>', '<Plug>(gina-show)zv')
endif

" Quickfix
if g:gina#command#grep#send_to_quickfix
  let s:Emitter = vital#gina#import('Emitter')
  function! s:on_exit(job, msg, event) abort
    let params = gina#util#path#params('%')
    if empty(params) || params.scheme !=# 'grep'
      return
    endif
    call gina#action#call('export:quickfix')
  endfunction
  call s:Emitter.subscribe('gina:stream:exit', function('s:on_exit'))
endif
