let s:Git = vital#gina#import('Git')
let s:Path = vital#gina#import('System.Filepath')


function! gina#repo#expand(expr) abort
  if a:expr !~# '^[%#<]'
    return expand(a:expr)
  endif
  let m = matchlist(a:expr, '^\([%#]\|<\w\+>\)\(.*\)')
  let expr = m[1]
  let modifiers = m[2]
  let params = gina#util#params(expr)
  return empty(params)
        \ ? expand(a:expr)
        \ : fnamemodify(expand(params.path), modifiers)
endfunction

function! gina#repo#abspath(path) abort
  let git = gina#core#get()
  return empty(git)
        \ ? s:Path.abspath(a:path)
        \ : s:Git.abspath(git, a:path)
endfunction

function! gina#repo#relpath(path) abort
  let git = gina#core#get()
  return empty(git)
        \ ? s:Path.relpath(a:path)
        \ : s:Git.relpath(git, a:path)
endfunction

function! gina#repo#config(git) abort
  let result = gina#core#process#call(a:git, ['config', '--list'])
  if result.status
    throw gina#core#process#error(result)
  endif
  let config = {}
  for record in filter(result.content, '!empty(v:val)')
    call s:extend_config(config, record)
  endfor
  return config
endfunction

" Private --------------------------------------------------------------------
function! s:extend_config(config, record) abort
  let m = matchlist(a:record, '^\(.*\)=\(.*\)$')
  let keys = split(m[1], '\.')
  let value = m[2]
  let cursor = a:config
  for key in keys[:-2]
    let cursor[key] = get(cursor, key, {})
    let cursor = cursor[key]
  endfor
  let cursor[keys[-1]] = value
endfunction
