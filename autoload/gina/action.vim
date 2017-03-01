let s:Action = vital#gina#import('Action')
let s:Action.name = 'gina'

function! gina#action#get(...) abort
  return call(s:Action.get, a:000, s:Action)
endfunction

function! gina#action#attach(...) abort
  return call(s:Action.attach, a:000, s:Action)
endfunction

function! gina#action#include(scheme) abort
  let binder = s:Action.get()
  if binder is# v:null
    " TODO: raise an exception
    return
  endif
  let scheme = substitute(a:scheme, '-', '_', 'g')
  try
    return call(
          \ printf('gina#action#%s#define', scheme),
          \ [binder]
          \)
  catch /^Vim\%((\a\+)\)\=:E117: [^:]\+: gina#action#[^#]\+#define/
    call gina#core#console#debug(v:exception)
    call gina#core#console#debug(v:throwpoint)
  endtry
  throw gina#core#exception#error(printf(
        \ 'No action script "gina/action/%s.vim" is found',
        \ a:scheme,
        \))
endfunction

function! gina#action#alias(...) abort
  let binder = s:Action.get()
  if binder is# v:null
    " TODO: raise an exception
    return
  endif
  return gina#core#exception#call(binder.alias, a:000, binder)
endfunction

function! gina#action#shorten(action_scheme, ...) abort
  let excludes = get(a:000, 0, [])
  let binder = s:Action.get()
  if binder is# v:null
    " TODO: raise an exception
    return
  endif
  let action_scheme = substitute(a:action_scheme, '-', '_', 'g')
  let names = filter(
        \ keys(binder.actions),
        \ 'v:val =~# ''^'' . action_scheme . '':'''
        \)
  for name in filter(names, 'index(excludes, v:val) == -1')
    call binder.alias(matchstr(name, '^' . action_scheme . ':\zs.*'), name)
  endfor
endfunction

function! gina#action#call(...) abort
  let binder = s:Action.get()
  if binder is# v:null
    " TODO: raise an exception
    return
  endif
  return gina#core#exception#call(binder.call, a:000, binder)
endfunction

function! gina#action#candidates(...) abort
  let binder = s:Action.get()
  if binder is# v:null
    return
  endif
  return gina#core#exception#call(binder.candidates, a:000, binder)
endfunction
