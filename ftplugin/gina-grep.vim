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
let params = gina#util#params('%')
if empty(get(params, 'revision'))
  call gina#util#nmap('<Return>', '<Plug>(gina-edit)zv')
else
  call gina#util#nmap('<Return>', '<Plug>(gina-show)zv')
endif

" Quickfix
if g:gina#command#grep#send_to_quickfix
  function! s:on_command_called(scheme) abort
    if a:scheme ==# 'grep'
      call gina#action#call('export:quickfix')
    endif
  endfunction
  call gina#core#emitter#subscribe('command:called', function('s:on_command_called'))
endif
