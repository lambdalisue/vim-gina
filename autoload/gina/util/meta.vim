let s:Cache = vital#gina#import('System.Cache.Memory')
let s:Exception = vital#gina#import('Vim.Exception')


function! gina#util#meta#get(...) abort
  let meta = s:meta('%')
  return call(meta.get, a:000, meta)
endfunction

function! gina#util#meta#set(...) abort
  let meta = s:meta('%')
  return call(meta.set, a:000, meta)
endfunction

function! gina#util#meta#has(...) abort
  let meta = s:meta('%')
  return call(meta.has, a:000, meta)
endfunction

function! gina#util#meta#remove(...) abort
  let meta = s:meta('%')
  return call(meta.remove, a:000, meta)
endfunction

function! gina#util#meta#clear(...) abort
  let meta = s:meta('%')
  return call(meta.clear, a:000, meta)
endfunction

function! gina#util#meta#get_or_fail(name) abort
  let meta = s:meta('%')
  if !meta.has(a:name)
    throw s:Exception.error(printf(
          \ 'A required meta value "%s" does not exist on "%s"',
          \ a:name,
          \ bufname('%'),
          \))
  endif
  return meta.get(a:name)
endfunction


" Private --------------------------------------------------------------------
function! s:meta(expr) abort
  let bufnr = bufnr(a:expr)
  if !bufexists(bufnr)
    " Always return a fresh cache instance
    return s:Cache.new()
  endif
  let meta = getbufvar(bufnr, 'gina_meta', {})
  if empty(meta)
    let meta = s:Cache.new()
    call setbufvar(bufnr, 'gina_meta', meta)
  endif
  return meta
endfunction
