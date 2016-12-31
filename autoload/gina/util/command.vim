let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')
let s:Exception = vital#gina#import('Vim.Exception')
let s:Observer = vital#gina#import('Vim.Buffer.Observer')


function! gina#util#command#attach() abort
  call s:Anchor.attach()
  call s:Observer.attach()
endfunction

function! gina#util#command#call(git, args) abort
  let result = s:Exception.call(
        \ 'gina#util#process#call',
        \ [a:git, a:args],
        \)
  if result.status
    throw gina#util#process#error(result)
  endif
  call gina#util#buffer#content(result.content)
endfunction
