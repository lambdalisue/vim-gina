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

if g:gina#command#status#use_default_aliases
  call gina#action#shorten('edit')
  call gina#action#shorten('index')
endif

if g:gina#command#status#use_default_mappings
  nmap <buffer> <Return> <Plug>(gina-edit)zv

  nmap <buffer> dd <Plug>(gina-diff)
  nmap <buffer> DD <Plug>(gina-diff-right)

  nmap <buffer> cc <Plug>(gina-compare)
  nmap <buffer> CC <Plug>(gina-compare-tab)

  nmap <buffer> pp <Plug>(gina-patch)
  nmap <buffer> PP <Plug>(gina-patch-tab)

  nmap <buffer> !! <Plug>(gina-chaperon)

  nmap <buffer> << <Plug>(gina-index-stage)
  nmap <buffer> >> <Plug>(gina-index-unstage)
  nmap <buffer> -- <Plug>(gina-index-toggle)
  nmap <buffer> == <Plug>(gina-index-discard)
  vmap <buffer> << <Plug>(gina-index-stage)
  vmap <buffer> >> <Plug>(gina-index-unstage)
  vmap <buffer> -- <Plug>(gina-index-toggle)
  vmap <buffer> == <Plug>(gina-index-discard)
endif
