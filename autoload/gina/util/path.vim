let s:Path = vital#gina#import('System.Filepath')
let s:String = vital#gina#import('Data.String')

function! gina#util#path#params(expr) abort
  let path = expand(a:expr)
  if path !~# '^gina:'
    return {}
  endif
  let m = matchlist(
        \ path,
        \ '\v^gina:%(//)?([^:]+):([^:/]+)([^/]*)/?([^:]*):?(.*)$',
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
  if empty(a:expr)
    return expand(a:expr)
  endif
  let params = gina#util#path#params(a:expr)
  return empty(params) ? expand(a:expr) : expand(params.path)
endfunction

function! gina#util#path#abspath(git, relpath) abort
  let relpath = s:Path.realpath(expand(a:relpath))
  if s:Path.is_absolute(relpath)
    return relpath
  endif
  return s:Path.join(a:git.worktree, relpath)
endfunction

function! gina#util#path#relpath(git, abspath) abort
  let abspath = s:Path.realpath(expand(a:abspath))
  if s:Path.is_relative(abspath)
    return abspath
  endif
  let pattern = s:String.escape_pattern(a:git.worktree . s:Path.separator())
  return abspath =~# '^' . pattern
        \ ? matchstr(abspath, '^' . pattern . '\zs.*')
        \ : abspath
endfunction
