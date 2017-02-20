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

" Does this buffer points files on working-tree or index/commit?
let s:is_worktree = empty(gina#core#buffer#param('%', 'revision'))

if g:gina#command#grep#use_default_aliases
  call gina#action#shorten('browse')
  call gina#action#shorten('export')
  if s:is_worktree
    call gina#action#shorten('edit')
  else
    call gina#action#shorten('show')
  endif
endif

if g:gina#command#grep#use_default_mappings
  if s:is_worktree
    nmap <buffer> <Return> <Plug>(gina-edit)zv
  else
    nmap <buffer> <Return> <Plug>(gina-show)zv
  endif

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
endif

if g:gina#command#grep#send_to_quickfix
  function! s:on_grep(scheme) abort
    if a:scheme !=# 'grep'
      return
    endif
    let focus = gina#core#buffer#focus(bufnr('gina://*:grep*'))
    if empty(focus)
      return
    endif
    try
      call gina#action#call('export:quickfix')
    finally
      call focus.restore()
    endtry
  endfunction
  call gina#core#emitter#subscribe('command:called', function('s:on_grep'))
endif
