function! gina#foldmethod#diff(lnum)
  return getline(a:lnum)     =~# '^@@'   ? '>1'
  \    : getline(a:lnum + 1) =~# '^diff' ? '<1'
  \    : getline(a:lnum + 1) =~# '^@@'   ? '<1'
  \                                      : '='
endfunction
