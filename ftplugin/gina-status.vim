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
  call gina#action#shorten('browse')
  call gina#action#shorten('edit')
  call gina#action#shorten('index')
  call gina#action#shorten('export')
endif

if g:gina#command#status#use_default_mappings
  nmap <buffer> <Return> <Plug>(gina-edit)zv

  nmap <buffer> oo <Plug>(gina-edit)zv
  nmap <buffer> OO <Plug>(gina-edit-right)zv
  nmap <buffer> oa <Plug>(gina-edit-above)zv
  nmap <buffer> ob <Plug>(gina-edit-below)zv
  nmap <buffer> or <Plug>(gina-edit-right)zv
  nmap <buffer> ol <Plug>(gina-edit-left)zv
  nmap <buffer> op <Plug>(gina-edit-preview)zv
  nmap <buffer> ot <Plug>(gina-edit-tab)zv

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

  nmap <buffer> <C-^> <Plug>(gina-status-commit)
endif
