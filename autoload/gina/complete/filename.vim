let s:Git = vital#gina#import('Git')
let s:Path = vital#gina#import('System.Filepath')
let s:Store = vital#gina#import('System.Store')
let s:String = vital#gina#import('Data.String')


function! gina#complete#filename#any(arglead, cmdline, cursorpos, ...) abort
  let git = gina#core#get_or_fail()
  let candidates = s:get_available_filenames(git, [
        \ '--cached', '--others', '--', a:arglead . '*',
        \])
  return s:filter(a:arglead, candidates)
endfunction

function! gina#complete#filename#tracked(arglead, cmdline, cursorpos, ...) abort
  let git = gina#core#get_or_fail()
  let slug = eval(s:Store.get_slug_expr())
  let store = s:Store.of(s:Git.resolve(git, 'index'))
  let candidates = store.get(slug, [])
  if empty(candidates)
    let candidates = s:get_available_filenames(git, [])
    call store.set(slug, candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! gina#complete#filename#cached(arglead, cmdline, cursorpos, ...) abort
  let git = gina#core#get_or_fail()
  let slug = eval(s:Store.get_slug_expr())
  let store = s:Store.of(s:Git.resolve(git, 'index'))
  let candidates = store.get(slug, [])
  if empty(candidates)
    let candidates = s:get_available_filenames(git, ['--cached'])
    call store.set(slug, candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! gina#complete#filename#deleted(arglead, cmdline, cursorpos, ...) abort
  let git = gina#core#get_or_fail()
  let slug = eval(s:Store.get_slug_expr())
  let store = s:Store.of(s:Git.resolve(git, 'index'))
  let candidates = store.get(slug, [])
  if empty(candidates)
    let candidates = s:get_available_filenames(git, ['--deleted'])
    call store.set(slug, candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! gina#complete#filename#modified(arglead, cmdline, cursorpos, ...) abort
  let git = gina#core#get_or_fail()
  let slug = eval(s:Store.get_slug_expr())
  let store = s:Store.of(s:Git.resolve(git, 'index'))
  let candidates = store.get(slug, [])
  if empty(candidates)
    let candidates = s:get_available_filenames(git, ['--modified'])
    call store.set(slug, candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! gina#complete#filename#others(arglead, cmdline, cursorpos, ...) abort
  let git = gina#core#get_or_fail()
  let candidates = s:get_available_filenames(git, [
        \ '--others', '--', a:arglead . '*',
        \])
  return s:filter(a:arglead, candidates)
endfunction

function! gina#complete#filename#unstaged(arglead, cmdline, cursorpos, ...) abort
  let git = gina#core#get_or_fail()
  let candidates = s:get_available_filenames(git, [
        \ '--others',
        \ '--modified',
        \ '--',
        \ a:arglead . '*',
        \])
  return s:filter(a:arglead, candidates)
endfunction


" Private --------------------------------------------------------------------
function! s:filter(arglead, candidates) abort
  let pattern = s:String.escape_pattern(a:arglead)
  let separator = s:Path.separator()
  let candidates = gina#util#filter(a:arglead, a:candidates, '^\.')
  call map(
        \ candidates,
        \ printf('matchstr(v:val, ''^%s[^%s]*\ze'')', pattern, separator),
        \)
  return uniq(candidates)
endfunction

function! s:get_available_filenames(git, args) abort
  let args = ['ls-files', '--full-name'] + a:args
  let result = gina#core#process#call(a:git, args)
  if result.status
    return []
  endif
  return map(result.stdout, 'fnamemodify(v:val, '':~:.'')')
endfunction
