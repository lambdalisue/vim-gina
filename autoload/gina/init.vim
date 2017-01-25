" Exception ------------------------------------------------------------------
let s:Exception = vital#gina#import('Vim.Exception')

function! s:exception_handler(exception) abort
  let m = matchlist(
        \ a:exception,
        \ '^vital: Git\.Term: ValidationError: \(.*\)',
        \)
  if !empty(m)
    call s:Console.warn(m[1])
    return 1
  endif
  return 0
endfunction

call s:Exception.register(
      \ function('s:exception_handler')
      \)
