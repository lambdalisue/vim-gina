let s:Action = vital#gina#import('Action')
let s:Console = vital#gina#import('Vim.Console')
let s:Exception = vital#gina#import('Vim.Exception')


function! gina#action#attach(...) abort
  return call(s:Action.attach, ['gina'] + a:000, s:Action)
endfunction

function! gina#action#include(scheme) abort
  let binder = s:get()
  let scheme = substitute(a:scheme, '-', '_', 'g')
  try
    return call(
          \ printf('gina#action#%s#define', scheme),
          \ [binder]
          \)
  catch /^Vim\%((\a\+)\)\=:E117: [^:]\+: gina#action#[^#]\+#define/
    call s:Console.debug(v:exception)
    call s:Console.debug(v:throwpoint)
  endtry
  throw s:Exception.error(printf(
        \ 'No action script "gina/action/%s.vim" is found',
        \ a:scheme,
        \))
endfunction

function! gina#action#alias(...) abort
  let binder = s:get()
  return call(binder.alias, a:000, binder)
endfunction

function! gina#action#call(name_or_alias, ...) abort
  let binder = s:get()
  let candidates = a:0 > 0 ? a:1 : binder.get_candidates(1, line('$'))
  return s:Exception.call(
        \ binder.call,
        \ [a:name_or_alias, candidates],
        \ binder
        \)
endfunction


" Private --------------------------------------------------------------------
function! s:get(...) abort
  return call(s:Action.get, ['gina'] + a:000, s:Action)
endfunction
