let s:Git = vital#gina#import('Git')


function! gina#core#rev#sha1(git, rev) abort
  let ref = s:Git.ref(a:git, a:rev)
  if !empty(ref)
    return ref.hash
  endif
  " Fallback to rev-parse (e.g. HEAD@{2.days.ago})
  let result = gina#process#call(a:git, ['rev-parse', a:rev])
  if result.status
    throw gina#process#errormsg(result)
  endif
  return get(result.stdout, 0, '')
endfunction

function! gina#core#rev#split(git, rev) abort
  if a:rev =~# '^.\{-}\.\.\..*$'
    let [lhs, rhs] = matchlist(a:rev, '^\(.\{-}\)\.\.\.\(.*\)$')[1 : 2]
    let rhs = empty(rhs) ? 'HEAD' : rhs
    let lhs = s:find_common_ancestor(a:git, lhs, rhs)
    return [lhs, rhs]
  elseif a:rev =~# '^.\{-}\.\..*$'
    let [lhs, rhs] = matchlist(a:rev, '^\(.\{-}\)\.\.\(.*\)$')[1 : 2]
    let lhs = empty(lhs) ? 'HEAD' : lhs
    let rhs = empty(rhs) ? 'HEAD' : rhs
    return [lhs, rhs]
  else
    return [a:rev, '']
  endif
endfunction

function! gina#core#rev#resolve(git, rev) abort
  if a:rev =~# '^.\{-}\.\.\..*$'
    let [lhs, rhs] = matchlist(a:rev, '^\(.\{-}\)\.\.\.\(.*\)$')[1 : 2]
    return s:find_common_ancestor(a:git, lhs, rhs)
  elseif a:rev =~# '^.\{-}\.\..*$'
    let [lhs, rhs] = matchlist(a:rev, '^\(.\{-}\)\.\.\(.*\)$')[1 : 2]
    return lhs
  else
    return a:rev
  endif
endfunction


" Private --------------------------------------------------------------------
function! s:find_common_ancestor(git, rev1, rev2) abort
  let lhs = empty(a:rev1) ? 'HEAD' : a:rev1
  let rhs = empty(a:rev2) ? 'HEAD' : a:rev2
  let result = gina#process#call(a:git, [
        \ 'merge-base', lhs, rhs
        \])
  if result.status
    throw gina#process#errormsg(result)
  endif
  return get(result.stdout, 0, '')
endfunction
