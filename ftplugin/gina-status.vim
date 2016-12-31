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
      \ 'silent! nunmap <buffer> <<',
      \ 'silent! nunmap <buffer> >>',
      \ 'silent! nunmap <buffer> --',
      \ 'silent! nunmap <buffer> ==',
      \ 'silent! vunmap <buffer> <<',
      \ 'silent! vunmap <buffer> >>',
      \ 'silent! vunmap <buffer> --',
      \ 'silent! vunmap <buffer> ==',
      \], ' | ')

setlocal winfixheight
setlocal nolist nospell
setlocal nowrap nofoldenable
setlocal nonumber norelativenumber
setlocal foldcolumn=0 colorcolumn=0

" Mappings
call gina#util#nmap('<Return>', '<Plug>(gina-edit)zv')
call gina#util#nmap('<<', '<Plug>(gina-index-stage)')
call gina#util#nmap('>>', '<Plug>(gina-index-unstage)')
call gina#util#nmap('--', '<Plug>(gina-index-toggle)')
call gina#util#nmap('==', '<Plug>(gina-index-discard)')
call gina#util#vmap('<<', '<Plug>(gina-index-stage)')
call gina#util#vmap('>>', '<Plug>(gina-index-unstage)')
call gina#util#vmap('--', '<Plug>(gina-index-toggle)')
call gina#util#vmap('==', '<Plug>(gina-index-discard)')
