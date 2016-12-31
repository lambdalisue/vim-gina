function! gina#complete#common#opener(arglead, cmdline, cursorpos, ...) abort
  if a:arglead !~# '^\%(-o\|--opener=\)'
    return []
  endif
  let candidates = [
        \ 'split',
        \ 'vsplit',
        \ 'tabedit',
        \ 'pedit',
        \]
  let prefix = a:arglead =~# '^-o' ? '-o' : '--opener='
  return gina#util#filter(a:arglead, map(candidates, 'prefix . v:val'))
endfunction
