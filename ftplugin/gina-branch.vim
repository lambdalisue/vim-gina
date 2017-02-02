if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal winfixheight
setlocal nolist nospell
setlocal nowrap nofoldenable
setlocal nonumber norelativenumber
setlocal foldcolumn=0 colorcolumn=0

if g:gina#command#branch#use_default_aliases
  call gina#action#shorten('branch')
  call gina#action#shorten('browse')
  call gina#action#shorten('commit')
  call gina#action#shorten('show')
endif

if g:gina#command#branch#use_default_mappings
  nmap <buffer> <Return> <Plug>(gina-branch-checkout)
  nmap <buffer> N <Plug>(gina-branch-new)
  nmap <buffer> M <Plug>(gina-branch-move)
  nmap <buffer> D <Plug>(gina-branch-delete)
  nmap <buffer> <C-^> <Plug>(gina-alternative)
endif
