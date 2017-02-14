let s:Git = vital#gina#import('Git')


function! gina#core#revision#sha1(git, revision) abort
  let ref = s:Git.ref(a:git, a:revision)
  if !empty(ref)
    return ref.hash
  endif
  " Fallback to rev-parse (e.g. HEAD@{2.days.ago})
  let result = gina#core#process#call(a:git, ['rev-parse', a:revision])
  if result.status
    throw gina#core#process#error(result)
  endif
  return get(result.stdout, 0, '')
endfunction

function! gina#core#revision#split(git, revision) abort
  if a:revision =~# '^.\{-}\.\.\..*$'
    let [lhs, rhs] = matchlist(a:revision, '^\(.\{-}\)\.\.\.\(.*\)$')[1 : 2]
    let rhs = empty(rhs) ? 'HEAD' : rhs
    let lhs = s:find_common_ancestor(a:git, lhs, rhs)
    return [lhs, rhs]
  elseif a:revision =~# '^.\{-}\.\..*$'
    let [lhs, rhs] = matchlist(a:revision, '^\(.\{-}\)\.\.\(.*\)$')[1 : 2]
    let lhs = empty(lhs) ? 'HEAD' : lhs
    let rhs = empty(rhs) ? 'HEAD' : rhs
    return [lhs, rhs]
  else
    return [a:revision, '']
  endif
endfunction

function! gina#core#revision#resolve(git, revision) abort
  if a:revision =~# '^.\{-}\.\.\..*$'
    let [lhs, rhs] = matchlist(a:revision, '^\(.\{-}\)\.\.\.\(.*\)$')[1 : 2]
    return s:find_common_ancestor(a:git, lhs, rhs)
  elseif a:revision =~# '^.\{-}\.\..*$'
    let [lhs, rhs] = matchlist(a:revision, '^\(.\{-}\)\.\.\(.*\)$')[1 : 2]
    return lhs
  else
    return a:revision
  endif
endfunction

function! gina#core#revision#count_ahead(git) abort
  let result = gina#core#process#call(a:git, [
        \ 'log', '--oneline', '@{upstream}..'
        \])
  if result.status
    throw gina#core#process#error(result)
  endif
  return len(filter(result.stdout, '!empty(v:val)'))
endfunction

function! gina#core#revision#count_behind(git) abort
  let result = gina#core#process#call(a:git, [
        \ 'log', '--oneline', '..@{upstream}'
        \])
  if result.status
    throw gina#core#process#error(result)
  endif
  return len(filter(result.stdout, '!empty(v:val)'))
endfunction


" Private --------------------------------------------------------------------
function! s:find_common_ancestor(git, revision1, revision2) abort
  let lhs = empty(a:revision1) ? 'HEAD' : a:revision1
  let rhs = empty(a:revision2) ? 'HEAD' : a:revision2
  let result = gina#core#process#call(a:git, [
        \ 'merge-base', lhs, rhs
        \])
  if result.status
    throw gina#core#process#error(result)
  endif
  return get(result.stdout, 0, '')
endfunction
