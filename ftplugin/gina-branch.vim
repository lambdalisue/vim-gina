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
call gina#util#nmap('<Return>', '<Plug>(gina-branch-checkout)')
