if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal nobuflisted
setlocal nolist nospell
setlocal nowrap nofoldenable
setlocal nonumber norelativenumber
setlocal foldcolumn=0 colorcolumn=0

if g:gina#command#blame#use_default_aliases
  call gina#action#shorten('blame')
endif

if g:gina#command#blame#use_default_mappings
  nmap <buffer> <Return>    <Plug>(gina-blame-open)
  nmap <buffer> <Backspace> <Plug>(gina-blame-back)
  nmap <buffer> <C-L>       <Plug>(gina-blame-C-L)
endif
