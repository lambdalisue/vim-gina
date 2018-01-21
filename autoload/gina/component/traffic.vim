scriptencoding utf-8

let s:Git = vital#gina#import('Git')
let s:Path = vital#gina#import('System.Filepath')
let s:Store = vital#gina#import('System.Store')


function! gina#component#traffic#ahead() abort
  let git = gina#core#get()
  if empty(git)
    return ''
  endif
  let slug = eval(s:Store.get_slug_expr())
  let ref = get(s:Git.ref(git, 'HEAD'), 'path', 'HEAD')
  let track = s:get_tracking_ref(git)
  let store = s:Store.of([
        \ s:Git.resolve(git, 'index'),
        \ s:Git.resolve(git, ref),
        \ s:Git.resolve(git, track),
        \])
  let ahead = store.get(slug, '')
  if !empty(ahead)
    return ahead
  endif
  let result = gina#process#call(git, [
        \ 'log',
        \ '--oneline',
        \ '@{upstream}..',
        \])
  if result.status
    return ''
  endif
  let ahead = len(filter(copy(result.stdout), '!empty(v:val)')) . ''
  call store.set(slug, ahead)
  return ahead
endfunction

function! gina#component#traffic#behind() abort
  let git = gina#core#get()
  if empty(git)
    return ''
  endif
  let slug = eval(s:Store.get_slug_expr())
  let ref = get(s:Git.ref(git, 'HEAD'), 'path', 'HEAD')
  let track = s:get_tracking_ref(git)
  let store = s:Store.of([
        \ s:Git.resolve(git, 'index'),
        \ s:Git.resolve(git, ref),
        \ s:Git.resolve(git, track),
        \])
  let behind = store.get(slug, '')
  if !empty(behind)
    return behind
  endif
  let result = gina#process#call(git, [
        \ 'log',
        \ '--oneline',
        \ '..@{upstream}',
        \])
  if result.status
    return ''
  endif
  let behind = len(filter(copy(result.stdout), '!empty(v:val)')) . ''
  call store.set(slug, behind)
  return behind
endfunction

function! gina#component#traffic#preset(...) abort
  let git = gina#core#get()
  if empty(git)
    return ''
  endif
  let kind = get(a:000, 0, 'ascii')
  return call('s:preset_' . kind, [])
endfunction

" Private --------------------------------------------------------------------
function! s:get_tracking_ref(git) abort
  let slug = eval(s:Store.get_slug_expr())
  let store = s:Store.of([
        \ s:Git.resolve(a:git, 'HEAD'),
        \ s:Git.resolve(a:git, 'config'),
        \])
  let ref = store.get(slug, '')
  if !empty(ref)
    return ref
  endif
  let result = gina#process#call(a:git, [
        \ 'rev-parse',
        \ '--symbolic-full-name',
        \ '@{upstream}',
        \])
  if result.status
    return ''
  endif
  let ref = get(result.stdout, 0)
  call store.set(slug, ref)
  return ref
endfunction

function! s:preset_ascii() abort
  let ahead = gina#component#traffic#ahead()
  let behind = gina#component#traffic#behind()
  let ahead = empty(ahead) ? '' : ('^' . ahead)
  let behind = empty(behind) ? '' : ('v' . behind)
  return join([ahead, behind])
endfunction

function! s:preset_fancy() abort
  let ahead = gina#component#traffic#ahead()
  let behind = gina#component#traffic#behind()
  let ahead = empty(ahead) ? '' : ('↑' . ahead)
  let behind = empty(behind) ? '' : ('↓' . behind)
  return join([ahead, behind])
endfunction
