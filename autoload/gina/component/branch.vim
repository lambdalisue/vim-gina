scriptencoding utf-8

let s:Git = vital#gina#import('Git')
let s:Path = vital#gina#import('System.Filepath')
let s:Store = vital#gina#import('System.Store')


function! gina#component#branch#local() abort
  let git = gina#core#get()
  if empty(git)
    return ''
  endif
  let slug = eval(s:Store.get_slug_expr())
  let store = s:Store.of([
        \ s:Git.resolve(git, 'HEAD'),
        \ s:Git.resolve(git, 'config'),
        \])
  let branch = store.get(slug, '')
  if !empty(branch)
    return branch
  endif
  let result = gina#process#call(git, [
        \ 'rev-parse',
        \ '--abbrev-ref',
        \ 'HEAD',
        \])
  if result.status
    return ''
  endif
  let branch = get(result.stdout, 0)
  call store.set(slug, branch)
  return branch
endfunction

function! gina#component#branch#track() abort
  let git = gina#core#get()
  if empty(git)
    return ''
  endif
  let slug = eval(s:Store.get_slug_expr())
  let store = s:Store.of([
        \ s:Git.resolve(git, 'HEAD'),
        \ s:Git.resolve(git, 'config'),
        \])
  let branch = store.get(slug, '')
  if !empty(branch)
    return branch
  endif
  let result = gina#process#call(git, [
        \ 'rev-parse',
        \ '--abbrev-ref',
        \ '--symbolic-full-name',
        \ '@{upstream}',
        \])
  if result.status
    return ''
  endif
  let branch = get(result.stdout, 0)
  call store.set(slug, branch)
  return branch
endfunction

function! gina#component#branch#preset(...) abort
  let kind = get(a:000, 0, 'ascii')
  return call('s:preset_' . kind, [])
endfunction


" Private --------------------------------------------------------------------
function! s:preset_ascii() abort
  let local = gina#component#branch#local()
  let track = gina#component#branch#track()
  if empty(track)
    return local
  endif
  return printf('%s -> %s', local, track)
endfunction

function! s:preset_fancy() abort
  let local = gina#component#branch#local()
  let track = gina#component#branch#track()
  if empty(track)
    return local
  endif
  return printf('%s → %s', local, track)
endfunction
