function! gina#action#branch#define(binder) abort
  call a:binder.define('branch:refresh', function('s:on_refresh'), {
        \ 'description': 'Refresh remote branches',
        \ 'mapping_mode': 'nv',
        \ 'requirements': [],
        \ 'options': {},
        \})
  call a:binder.define('branch:checkout', function('s:on_checkout'), {
        \ 'description': 'Checkout a branch',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['branch', 'remote'],
        \ 'options': {},
        \})
  call a:binder.define('branch:checkout:track', function('s:on_checkout'), {
        \ 'description': 'Checkout a branch and create a local branch',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['branch', 'remote'],
        \ 'options': {'track': 1},
        \})
  call a:binder.define('branch:delete', function('s:on_delete'), {
        \ 'description': 'Delete a branch',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['branch', 'remote'],
        \ 'options': {},
        \})
  call a:binder.define('branch:delete:force', function('s:on_delete'), {
        \ 'description': 'Delete a branch',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['branch', 'remote'],
        \ 'options': { 'force': 1 },
        \})
  call a:binder.define('branch:move', function('s:on_move'), {
        \ 'description': 'Rename a branch',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['branch', 'remote'],
        \ 'options': {},
        \})
  call a:binder.define('branch:move:force', function('s:on_move'), {
        \ 'description': 'Rename a branch',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['branch', 'remote'],
        \ 'options': { 'force': 1 },
        \})
  call a:binder.define('branch:new', function('s:on_new'), {
        \ 'description': 'Create a new branch',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['branch', 'remote'],
        \ 'options': {},
        \})
  call a:binder.define('branch:set-upstream-to', function('s:on_set_upstream_to'), {
        \ 'description': 'Set upstream of a branch',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['branch', 'remote'],
        \ 'options': {},
        \})
  call a:binder.define('branch:unset-upstream', function('s:on_unset_upstream'), {
        \ 'description': 'Unset upstream of a branch',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['branch', 'remote'],
        \ 'options': {},
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_refresh(candidates, options) abort
  execute 'Gina remote update --prune'
endfunction

function! s:on_checkout(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'track': 0,
        \}, a:options)
  for candidate in a:candidates
    if options.track
      let branch = candidate.remote ==# 'origin'
            \ ? candidate.branch
            \ : candidate.rev
      execute printf(
            \ 'Gina checkout -b %s %s',
            \ gina#util#shellescape(branch),
            \ gina#util#shellescape(candidate.rev),
            \)
    else
      execute printf(
            \ 'Gina checkout %s',
            \ gina#util#shellescape(candidate.rev),
            \)
    endif
  endfor
endfunction

function! s:on_new(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({}, a:options)
  for candidate in a:candidates
    let name = gina#core#console#ask(
          \ 'Name: ', '',
          \)
    let from = gina#core#console#ask(
          \ 'From: ', candidate.rev,
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
  let candidates = filter(copy(a:candidates), 'empty(v:val.remote)')
  if empty(candidates)
    return
  endif
  let options = extend({
        \ 'force': 0,
        \}, a:options)
  for candidate in candidates
    let name = gina#core#console#ask(
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
  let options = extend({
        \ 'force': 0,
        \}, a:options)
  for candidate in a:candidates
    let is_remote = !empty(candidate.remote)
    if is_remote
      execute printf(
            \ 'Gina push --delete %s %s %s',
            \ options.force ? '--force' : '',
            \ gina#util#shellescape(candidate.remote),
            \ gina#util#shellescape(candidate.branch),
            \)
    else
      execute printf(
            \ 'Gina branch --delete %s %s',
            \ options.force ? '--force' : '',
            \ gina#util#shellescape(candidate.branch),
            \)
    endif
  endfor
endfunction

function! s:on_set_upstream_to(candidates, options) abort
  let candidates = filter(copy(a:candidates), 'empty(v:val.remote)')
  if empty(candidates)
    return
  endif
  let options = extend({}, a:options)
  for candidate in candidates
    let upstream = gina#core#console#ask(
          \ 'Upstream: ',
          \ candidate.branch,
          \ function('gina#complete#commit#remote_branch'),
          \)
    let upstream = substitute(
          \ upstream, printf('^%s/', candidate.remote), '', ''
          \)
    execute printf(
          \ 'Gina branch --set-upstream-to=%s %s',
          \ gina#util#shellescape(upstream),
          \ gina#util#shellescape(candidate.branch),
          \)
  endfor
endfunction

function! s:on_unset_upstream(candidates, options) abort
  let candidates = filter(copy(a:candidates), 'empty(v:val.remote)')
  if empty(candidates)
    return
  endif
  let options = extend({}, a:options)
  for candidate in candidates
    execute printf(
          \ 'Gina branch --unset-upstream %s',
          \ gina#util#shellescape(candidate.branch),
          \)
  endfor
endfunction
