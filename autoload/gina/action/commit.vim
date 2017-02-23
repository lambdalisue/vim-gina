function! gina#action#commit#define(binder) abort
  call a:binder.define('commit:merge', function('s:on_merge'), {
        \ 'description': 'Merge the commit into HEAD',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': {},
        \})
  call a:binder.define('commit:merge:ff-only', function('s:on_merge'), {
        \ 'hidden': 1,
        \ 'description': 'Merge the commit into HEAD',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': { 'ff-only': 1 },
        \})
  call a:binder.define('commit:merge:no-ff', function('s:on_merge'), {
        \ 'hidden': 1,
        \ 'description': 'Merge the commit into HEAD',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': { 'no-ff': 1 },
        \})
  call a:binder.define('commit:merge:squash', function('s:on_merge'), {
        \ 'hidden': 1,
        \ 'description': 'Merge the commit into HEAD',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': { 'squash': 1 },
        \})
  call a:binder.define('commit:rebase', function('s:on_rebase'), {
        \ 'description': 'Rebase HEAD from the commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': {},
        \})
  call a:binder.define('commit:rebase:merge', function('s:on_rebase'), {
        \ 'hidden': 1,
        \ 'description': 'Rebase HEAD by merging the commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': { 'merge': 1 },
        \})
  call a:binder.define('commit:revert', function('s:on_revert'), {
        \ 'description': 'Revert the commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': {},
        \})
  call a:binder.define('commit:revert:1', function('s:on_revert'), {
        \ 'hidden': 1,
        \ 'description': 'Revert the commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': { 'mainline': '1' },
        \})
  call a:binder.define('commit:revert:2', function('s:on_revert'), {
        \ 'hidden': 1,
        \ 'description': 'Revert the commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': { 'mainline': '2' },
        \})
  call a:binder.define('commit:cherry-pick', function('s:on_cherry_pick'), {
        \ 'description': 'Apply the changes of the commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': {},
        \})
  call a:binder.define('commit:cherry-pick:1', function('s:on_cherry_pick'), {
        \ 'hidden': 1,
        \ 'description': 'Apply the changes of the commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': { 'mainline': '1' },
        \})
  call a:binder.define('commit:cherry-pick:2', function('s:on_cherry_pick'), {
        \ 'hidden': 1,
        \ 'description': 'Apply the changes of the commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': { 'mainline': '2' },
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_merge(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'no-ff': 0,
        \ 'ff-only': 0,
        \ 'squash': 0,
        \}, a:options)
  for candidate in a:candidates
    execute printf(
          \ 'Gina merge --no-edit %s %s %s -- %s',
          \ options['no-ff'] ? '--no-ff' : '',
          \ options['ff-only'] ? '--ff-only' : '',
          \ options.squash ? '--squash' : '',
          \ gina#util#shellescape(candidate.rev),
          \)
  endfor
endfunction

function! s:on_rebase(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'merge': 0,
        \}, a:options)
  for candidate in a:candidates
    execute printf(
          \ 'Gina rebase %s -- %s',
          \ options.merge ? '--merge' : '',
          \ gina#util#shellescape(candidate.rev),
          \)
  endfor
endfunction

function! s:on_revert(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'mainline': '',
        \}, a:options)
  for candidate in a:candidates
    execute printf(
          \ 'Gina revert %s %s',
          \ gina#util#shellescape(options.mainline, '--mainline'),
          \ gina#util#shellescape(candidate.rev),
          \)
  endfor
endfunction

function! s:on_cherry_pick(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'mainline': '',
        \}, a:options)
  for candidate in a:candidates
    execute printf(
          \ 'Gina cherry-pick %s %s',
          \ gina#util#shellescape(options.mainline, '--mainline'),
          \ gina#util#shellescape(candidate.rev),
          \)
  endfor
endfunction
