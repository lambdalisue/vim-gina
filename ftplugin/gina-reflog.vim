if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal winfixheight
setlocal nolist nospell
setlocal nowrap nofoldenable
setlocal nonumber norelativenumber
setlocal foldcolumn=0 colorcolumn=0

if g:gina#command#reflog#use_default_aliases
  call gina#action#shorten('browse')
  call gina#action#shorten('commit')
  call gina#action#shorten('show')
endif

if g:gina#command#reflog#use_default_mappings
  nmap <buffer> <Return> <Plug>(gina-show)zv

  nmap <buffer> ss <Plug>(gina-show)zv
  nmap <buffer> SS <Plug>(gina-show-right)zv
  nmap <buffer> sa <Plug>(gina-show-above)zv
  nmap <buffer> sb <Plug>(gina-show-below)zv
  nmap <buffer> sr <Plug>(gina-show-right)zv
  nmap <buffer> sl <Plug>(gina-show-left)zv
  nmap <buffer> sp <Plug>(gina-show-preview)zv
  nmap <buffer> st <Plug>(gina-show-tab)zv

  nmap <buffer> dd <Plug>(gina-diff)
  nmap <buffer> DD <Plug>(gina-diff-right)
  nmap <buffer> da <Plug>(gina-diff-above)
  nmap <buffer> db <Plug>(gina-diff-below)
  nmap <buffer> dr <Plug>(gina-diff-right)
  nmap <buffer> dl <Plug>(gina-diff-left)
  nmap <buffer> dp <Plug>(gina-diff-preview)
  nmap <buffer> dt <Plug>(gina-diff-tab)

  nmap <buffer> cc <Plug>(gina-compare)
  nmap <buffer> CC <Plug>(gina-compare-tab)
endif
