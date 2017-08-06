scriptencoding utf-8

let s:Git = vital#gina#import('Git')
let s:Path = vital#gina#import('System.Filepath')
let s:Store = vital#gina#import('System.Store')


function! gina#component#repo#name() abort
  let git = gina#core#get()
  if empty(git)
    return ''
  endif
  return fnamemodify(git.worktree, ':t')
endfunction

function! gina#component#repo#branch() abort
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
  let branch = gina#core#treeish#resolve(git, 'HEAD', 1)
  call store.set(slug, branch)
  return branch
endfunction

function! gina#component#repo#track() abort
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

function! gina#component#repo#preset(...) abort
  let kind = get(a:000, 0, 'ascii')
  return call('s:preset_' . kind, [])
endfunction


" Private --------------------------------------------------------------------
function! s:preset_ascii() abort
  let name = gina#component#repo#name()
  let branch = gina#component#repo#branch()
  let track = gina#component#repo#track()
  if empty(track)
    return printf('%s [%s]', name, branch)
  endif
  return printf('%s [%s -> %s]', name, branch, track)
endfunction

function! s:preset_fancy() abort
  let name = gina#component#repo#name()
  let branch = gina#component#repo#branch()
  let track = gina#component#repo#track()
  if empty(track)
    return printf('%s [%s]', name, branch)
  endif
  return printf('%s [%s → %s]', name, branch, track)
endfunction
