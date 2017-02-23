let s:Path = vital#gina#import('System.Filepath')
let s:Git = vital#gina#import('Git')


function! gina#core#treeish#split(treeish) abort
  " Ref: https://git-scm.com/docs/gitrevisions
  if a:treeish =~# '^:/' || a:treeish =~# '^[^:]*^{/' || a:treeish !~# ':'
    return [a:treeish, v:null]
  endif
  let m = matchlist(a:treeish, '^\(:[0-3]\|[^:]*\)\%(:\(.*\)\)\?$')
  return [m[1], m[2]]
endfunction

function! gina#core#treeish#build(rev, path) abort
  if a:path is# v:null
    return a:rev
  endif
  return printf('%s:%s', a:rev, s:Path.unixpath(a:path))
endfunction

function! gina#core#treeish#sha1(git, rev) abort
  let ref = s:Git.ref(a:git, a:rev)
  if !empty(ref)
    return ref.hash
  endif
  " Fallback to rev-parse (e.g. HEAD@{2.days.ago})
  let result = gina#process#call_or_fail(a:git, ['rev-parse', a:rev])
  return get(result.stdout, 0, '')
endfunction

function! gina#core#treeish#split_rev(git, rev) abort
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

function! gina#core#treeish#resolve_rev(git, rev) abort
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
  let result = gina#process#call_or_fail(a:git, [
        \ 'merge-base', lhs, rhs
        \])
  return get(result.stdout, 0, '')
endfunction
