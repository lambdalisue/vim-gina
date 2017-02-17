if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal nobuflisted
setlocal winfixheight
setlocal nolist nospell
setlocal nowrap nofoldenable
setlocal nonumber norelativenumber
setlocal foldcolumn=0 colorcolumn=0

if g:gina#command#reflog#use_default_aliases
  call gina#action#shorten('browse')
  call gina#action#shorten('commit')
  call gina#action#shorten('info')
endif

if g:gina#command#reflog#use_default_mappings
  nmap <buffer> <Return> <Plug>(gina-info)zv

  nmap <buffer> ii <Plug>(gina-info)zv
  nmap <buffer> II <Plug>(gina-info-right)zv
  nmap <buffer> ia <Plug>(gina-info-above)zv
  nmap <buffer> ib <Plug>(gina-info-below)zv
  nmap <buffer> ir <Plug>(gina-info-right)zv
  nmap <buffer> il <Plug>(gina-info-left)zv
  nmap <buffer> ip <Plug>(gina-info-preview)zv
  nmap <buffer> it <Plug>(gina-info-tab)zv

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
