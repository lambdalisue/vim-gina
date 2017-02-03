function! gina#core#commit#split(git, commit) abort
  if a:commit =~# '^.\{-}\.\.\..*$'
    let [lhs, rhs] = matchlist(a:commit, '^\(.\{-}\)\.\.\.\(.*\)$')[1 : 2]
    let rhs = empty(rhs) ? 'HEAD' : rhs
    let lhs = s:find_common_ancestor(a:git, lhs, rhs)
    return [lhs, rhs]
  elseif a:commit =~# '^.\{-}\.\..*$'
    let [lhs, rhs] = matchlist(a:commit, '^\(.\{-}\)\.\.\(.*\)$')[1 : 2]
    let lhs = empty(lhs) ? 'HEAD' : lhs
    let rhs = empty(rhs) ? 'HEAD' : rhs
    return [lhs, rhs]
  else
    return [a:commit, '']
  endif
endfunction

function! gina#core#commit#resolve(git, commit) abort
  if a:commit =~# '^.\{-}\.\.\..*$'
    let [lhs, rhs] = matchlist(a:commit, '^\(.\{-}\)\.\.\.\(.*\)$')[1 : 2]
    return s:find_common_ancestor(a:git, lhs, rhs)
  elseif a:commit =~# '^.\{-}\.\..*$'
    let [lhs, rhs] = matchlist(a:commit, '^\(.\{-}\)\.\.\(.*\)$')[1 : 2]
    return lhs
  else
    return a:commit
  endif
endfunction

function! gina#core#commit#count_ahead(git) abort
  let result = gina#core#process#call(a:git, [
        \ 'log', '--oneline', '@{upstream}..'
        \])
  if result.status
    throw gina#core#process#error(result)
  endif
  return len(filter(result.stdout, '!empty(v:val)'))
endfunction

function! gina#core#commit#count_behind(git) abort
  let result = gina#core#process#call(a:git, [
        \ 'log', '--oneline', '..@{upstream}'
        \])
  if result.status
    throw gina#core#process#error(result)
  endif
  return len(filter(result.stdout, '!empty(v:val)'))
endfunction


" Private --------------------------------------------------------------------
function! s:find_common_ancestor(git, commit1, commit2) abort
  let lhs = empty(a:commit1) ? 'HEAD' : a:commit1
  let rhs = empty(a:commit2) ? 'HEAD' : a:commit2
  let result = gina#core#process#call(a:git, [
        \ 'merge-base', lhs, rhs
        \])
  if result.status
    throw gina#core#process#error(result)
  endif
  return get(result.stdout, 0, '')
endfunction
