if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal nomodeline
setlocal nobuflisted
setlocal nolist nospell
setlocal nowrap nofoldenable
setlocal nonumber norelativenumber
setlocal foldcolumn=0 colorcolumn=0

if g:gina#command#changes#use_default_aliases
  call gina#action#shorten('edit')
endif

if g:gina#command#changes#use_default_mappings
  nmap <buffer> <Return> <Plug>(gina-edit)zv

  nmap <buffer> dd <Plug>(gina-diff)
  nmap <buffer> DD <Plug>(gina-diff-right)

  nmap <buffer> cc <Plug>(gina-compare)
  nmap <buffer> CC <Plug>(gina-compare-tab)
endif
