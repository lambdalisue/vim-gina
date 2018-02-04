function! s:find_path_and_lnum(git) abort
  if getline('.') =~# '^-'
    return s:find_path_and_lnum_lhs(a:git)
  elseif getline('.') =~# '^[ +]'
    return s:find_path_and_lnum_rhs(a:git)
  else
    return v:null
  endif
endfunction

function! s:find_path_and_lnum_lhs(git) abort
  let lnum = search('^@@', 'bnW')
  let path = matchstr(
        \ getline(search('^--- a/', 'bnW')),
        \ '^--- a/\zs.*$'
        \)
  let m = matchlist(
        \ getline(lnum),
        \ '^@@ -\(\d\+\)\%(,\(\d\+\)\)\? +\(\d\+\),\(\d\+\) @@\(.*\)$'
        \)
  if empty(m)
    return v:null
  endif
  let n = len(filter(
        \ map(range(lnum, line('.')), 'getline(v:val)'),
        \ 'v:val !~# ''^+''')
        \)
  return {'path': path, 'lnum': m[1] + n - 2, 'side': 0}
endfunction

function! s:find_path_and_lnum_rhs(git) abort
  if getline('.') !~# '^[ -+]'
    return v:null
  endif
  let lnum = search('^@@', 'bnW')
  let path = matchstr(
        \ getline(search('^+++ b/', 'bnW')),
        \ '^+++ b/\zs.*$'
        \)
  let m = matchlist(
        \ getline(lnum),
        \ '^@@ -\(\d\+\)\%(,\(\d\+\)\)\? +\(\d\+\),\(\d\+\) @@\(.*\)$'
        \)
  if empty(m)
    return v:null
  endif
  let n = len(filter(
        \ map(range(lnum, line('.')), 'getline(v:val)'),
        \ 'v:val !~# ''^-''')
        \)
  return {'path': path, 'lnum': m[3] + n - 2, 'side': 1}
endfunction

function! s:jump(opener) abort
  let git = gina#core#get_or_fail()
  let pathinfo = s:find_path_and_lnum(git)
  if pathinfo is v:null
    return 0
  endif

  let rev = gina#core#buffer#param(bufname('%'), 'rev')
  let rev = gina#core#treeish#split(rev)[pathinfo.side]
  if empty(rev) && pathinfo.side == 1
    call gina#core#console#debug(printf(
          \ 'Gina edit --line=%d --opener=%s %s',
          \ pathinfo.lnum,
          \ a:opener,
          \ pathinfo.path,
          \))
    execute printf(
          \ 'Gina edit --line=%d --opener=%s %s',
          \ pathinfo.lnum,
          \ a:opener,
          \ pathinfo.path,
          \)
  else
    call gina#core#console#debug(printf(
          \ 'Gina show --line=%d --opener=%s %s:%s',
          \ pathinfo.lnum,
          \ a:opener,
          \ rev,
          \ pathinfo.path,
          \))
    execute printf(
          \ 'Gina show --line=%d --opener=%s %s:%s',
          \ pathinfo.lnum,
          \ a:opener,
          \ rev,
          \ pathinfo.path,
          \)
  endif
  return 1
endfunction

function! gina#core#diffjump#jump(...) abort
  let opener = a:0 ? a:1 : ''
  let opener = empty(opener) ? 'edit' : opener
  return gina#core#revelator#call(
        \ function('s:jump'),
        \ [opener],
        \)
endfunction
