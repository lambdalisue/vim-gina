let s:Git = vital#gina#import('Git')
let s:Path = vital#gina#import('System.Filepath')
let s:String = vital#gina#import('Data.String')


function! gina#util#path#params(expr) abort
  let path = expand(a:expr)
  if path !~# '^gina:'
    return {}
  endif
  let m = matchlist(
        \ path,
        \ '\v^gina:%(//)?([^:]+):([^:\/]+)([^\/]*)[\/]?([^:]*):?(.*)$',
        \)
  return {
        \ 'repo': m[1],
        \ 'scheme': m[2],
        \ 'params': split(m[3], ':'),
        \ 'commit': m[4],
        \ 'path': m[5],
        \}
endfunction

function! gina#util#path#expand(expr) abort
  if a:expr !~# '^[%#<]'
    return expand(a:expr)
  endif
  let m = matchlist(a:expr, '^\([%#]\|<\w\+>\)\(.*\)')
  let expr = m[1]
  let modifiers = m[2]
  let params = gina#util#path#params(expr)
  return empty(params)
        \ ? expand(a:expr)
        \ : fnamemodify(expand(params.path), modifiers)
endfunction

function! gina#util#path#abspath(git, path) abort
  return s:Git.abspath(a:git, a:path)
endfunction

function! gina#util#path#relpath(git, path) abort
  return s:Git.relpath(a:git, a:path)
endfunction
