function! gina#core#repo#abspath(git, expr) abort
  return gina#core#path#abspath(a:expr, a:git.worktree)
endfunction

function! gina#core#repo#relpath(git, expr) abort
  return gina#core#path#relpath(a:expr, a:git.worktree)
endfunction

function! gina#core#repo#config(git) abort
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
  let m = matchlist(a:record, '^\(.\+\)=\(.*\)$')
  if empty(m)
    return
  endif
  let keys = filter(split(m[1], '\.'), '!empty(v:val)')
  let value = m[2]
  let cursor = a:config
  for key in keys[:-2]
    let cursor[key] = get(cursor, key, {})
    let cursor = cursor[key]
  endfor
  let cursor[keys[-1]] = value
endfunction
