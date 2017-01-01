let s:Console = vital#gina#import('Vim.Console')


function! gina#action#branch#define(binder) abort
  call a:binder.define('branch:checkout', function('s:on_checkout'), {
        \ 'description': 'Checkout a branch',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['branch'],
        \ 'options': {},
        \})
  call a:binder.define('branch:delete', function('s:on_delete'), {
        \ 'description': 'Delete a branch',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['branch'],
        \ 'options': {},
        \})
  call a:binder.define('branch:delete:force', function('s:on_delete'), {
        \ 'description': 'Delete a branch',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['branch'],
        \ 'options': { 'force': 1 },
        \})
  call a:binder.define('branch:move', function('s:on_move'), {
        \ 'description': 'Rename a branch',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['branch'],
        \ 'options': {},
        \})
  call a:binder.define('branch:move:force', function('s:on_move'), {
        \ 'description': 'Rename a branch',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['branch'],
        \ 'options': { 'force': 1 },
        \})
  call a:binder.define('branch:new', function('s:on_new'), {
        \ 'description': 'Create a new branch',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['branch'],
        \ 'options': {},
        \})
  call a:binder.define('branch:set-upstream-to', function('s:on_set_upstream_to'), {
        \ 'description': 'Set upstream of a branch',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['branch'],
        \ 'options': {},
        \})
  call a:binder.define('branch:unset-upstream', function('s:on_unset_upstream'), {
        \ 'description': 'Unset upstream of a branch',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['branch'],
        \ 'options': {},
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_checkout(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let git = gina#core#get_or_fail()
  let options = extend({}, a:options)
  for candidate in a:candidates
    execute printf(
          \ 'Gina checkout %s',
          \ gina#util#shellescape(candidate.branch),
          \)
  endfor
endfunction

function! s:on_new(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let git = gina#core#get_or_fail()
  let options = extend({}, a:options)
  for candidate in a:candidates
    let name = s:Console.ask(
          \ 'Name: ', '',
          \)
    let from = s:Console.ask(
          \ 'From: ', candidate.branch,
          \ 'customlist,gina#complete#commit#branch',
          \)
    execute printf(
          \ 'Gina checkout -b %s %s',
          \ gina#util#shellescape(name),
          \ gina#util#shellescape(from),
          \)
  endfor
endfunction

function! s:on_move(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let git = gina#core#get_or_fail()
  let options = extend({
        \ 'force': 0,
        \}, a:options)
  for candidate in a:candidates
    let name = s:Console.ask(
          \ 'Rename: ',
          \ candidate.branch,
          \)
    execute printf(
          \ 'Gina branch --move %s %s %s',
          \ options.force ? '--force' : '',
          \ gina#util#shellescape(candidate.branch),
          \ gina#util#shellescape(name),
          \)
  endfor
endfunction

function! s:on_delete(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let git = gina#core#get_or_fail()
  let options = extend({
        \ 'force': 0,
        \}, a:options)
  for candidate in a:candidates
    execute printf(
          \ 'Gina branch --delete %s %s %s',
          \ options.force ? '--force' : '',
          \ empty(candidate.remote) ? '' : '--remotes',
          \ gina#util#shellescape(candidate.branch),
          \)
  endfor
endfunction

function! s:on_set_upstream_to(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let git = gina#core#get_or_fail()
  let options = extend({}, a:options)
  for candidate in a:candidates
    let upstream = s:Console.ask(
          \ 'Upstream: ',
          \ candidate.branch,
          \ function('gina#complete#commit#remote_branch'),
          \)
    execute printf(
          \ 'Gina branch --set-upstream-to=%s %s',
          \ gina#util#shellescape(upstream),
          \ gina#util#shellescape(candidate.branch),
          \)
  endfor
endfunction

function! s:on_unset_upstream(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let git = gina#core#get_or_fail()
  let options = extend({}, a:options)
  for candidate in a:candidates
    execute printf(
          \ 'Gina branch --unset-upstream %s',
          \ gina#util#shellescape(candidate.branch),
          \)
  endfor
endfunction
