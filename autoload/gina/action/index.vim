let s:Console = vital#gina#import('Vim.Console')
let s:File = vital#gina#import('System.File')
let s:Path = vital#gina#import('System.Filepath')


function! gina#action#index#define(binder, ...) abort
  call a:binder.define('index:add', function('s:on_add'), {
        \ 'hidden': 1,
        \ 'description': 'Add a change to the status',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': {},
        \})
  call a:binder.define('index:add:force', function('s:on_add'), {
        \ 'hidden': 1,
        \ 'description': 'Add a change to the status',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'force': 1 },
        \})
  call a:binder.define('index:add:intent-to-add', function('s:on_add'), {
        \ 'hidden': 1,
        \ 'description': 'Intent to add a change to the status',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'intent-to-add': 1 },
        \})
  call a:binder.define('index:rm', function('s:on_rm'), {
        \ 'hidden': 1,
        \ 'description': 'Remove files from the working tree and from the status',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': {},
        \})
  call a:binder.define('index:rm:cached', function('s:on_rm'), {
        \ 'hidden': 1,
        \ 'description': 'Remove files from the status but the working tree',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'cached': 1 },
        \})
  call a:binder.define('index:rm:force', function('s:on_rm'), {
        \ 'hidden': 1,
        \ 'description': 'Remove files from the working tree and from the status (force)',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'force': 1 },
        \})
  call a:binder.define('index:reset', function('s:on_reset'), {
        \ 'hidden': 1,
        \ 'description': 'Reset changes on the status',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': {},
        \})
  call a:binder.define('index:stage', function('s:on_stage'), {
        \ 'description': 'Stage changes to the status',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'sign'],
        \ 'options': {},
        \})
  call a:binder.define('index:stage:force', function('s:on_stage'), {
        \ 'hidden': 1,
        \ 'description': 'Stage changes to the status',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'sign'],
        \ 'options': { 'force': 1 },
        \})
  call a:binder.define('index:unstage', function('s:on_unstage'), {
        \ 'description': 'Unstage changes from the status',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'sign'],
        \ 'options': {},
        \})
  call a:binder.define('index:toggle', function('s:on_toggle'), {
        \ 'description': 'Toggle stage/unstage of changes in the status',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'sign'],
        \ 'options': {},
        \})
  call a:binder.define('index:checkout', function('s:on_checkout'), {
        \ 'hidden': 1,
        \ 'description': 'Checkout a contents',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': {},
        \})
  call a:binder.define('index:checkout:force', function('s:on_checkout'), {
        \ 'hidden': 1,
        \ 'description': 'Checkout a contents (force)',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'force': 1 },
        \})
  call a:binder.define('index:checkout:ours', function('s:on_checkout'), {
        \ 'description': 'Checkout a contents',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'ours': 1 },
        \})
  call a:binder.define('index:checkout:theirs', function('s:on_checkout'), {
        \ 'description': 'Checkout a contents',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'theirs': 1 },
        \})
  call a:binder.define('index:checkout:HEAD', function('s:on_checkout'), {
        \ 'hidden': 1,
        \ 'description': 'Checkout a contents from HEAD',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'revision': 'HEAD' },
        \})
  call a:binder.define('index:checkout:HEAD:force', function('s:on_checkout'), {
        \ 'hidden': 1,
        \ 'description': 'Checkout a contents from HEAD (force)',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'revision': 'HEAD', 'force': 1 },
        \})
  call a:binder.define('index:checkout:origin', function('s:on_checkout'), {
        \ 'description': 'Checkout a contents from origin/HEAD',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'revision': 'origin/HEAD' },
        \})
  call a:binder.define('index:checkout:origin:force', function('s:on_checkout'), {
        \ 'hidden': 1,
        \ 'description': 'Checkout a contents from origin/HEAD (force)',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'revision': 'origin/HEAD', 'force': 1 },
        \})
  call a:binder.define('index:discard', function('s:on_discard'), {
        \ 'description': 'Discard changes on the working tree',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'sign'],
        \ 'options': {},
        \})
  call a:binder.define('index:discard:force', function('s:on_discard'), {
        \ 'hidden': 1,
        \ 'description': 'Discard changes on the working tree',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'sign'],
        \ 'options': { 'force': 1 },
        \})

  if get(a:000, 0, 0)
    call gina#action#alias('stage', 'index:stage')
    call gina#action#alias('unstage', 'index:unstage')
    call gina#action#alias('toggle', 'index:toggle')
    call gina#action#alias('checkout:ours', 'index:checkout:ours')
    call gina#action#alias('checkout:theirs', 'index:checkout:theirs')
    call gina#action#alias('checkout:origin', 'index:checkout:origin')
    call gina#action#alias('discard', 'index:discard')
  endif
endfunction


function! s:on_add(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let git = gina#core#get_or_fail()
  let options = extend({
        \ 'force': 0,
        \ 'intent-to-add': 0,
        \}, a:options)
  let pathlist = map(
        \ copy(a:candidates),
        \ 'gina#util#fnameescape(gina#util#abspath(v:val.path))',
        \)
  execute printf(
        \ 'Gina add --ignore-errors %s %s -- %s',
        \ options.force ? '--force' : '',
        \ options['intent-to-add'] ? '--intent-to-add' : '',
        \ join(pathlist),
        \)
endfunction

function! s:on_rm(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let git = gina#core#get_or_fail()
  let options = extend({
        \ 'cached': 0,
        \ 'force': 0,
        \}, a:options)
  let pathlist = map(
        \ copy(a:candidates),
        \ 'gina#util#fnameescape(gina#util#abspath(v:val.path))',
        \)
  execute printf(
        \ 'Gina rm --quiet --ignore-unmatch %s %s -- %s',
        \ options.force ? '--force' : '',
        \ options.cached ? '--cached' : '',
        \ join(pathlist),
        \)
endfunction

function! s:on_reset(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let git = gina#core#get_or_fail()
  let options = extend({}, a:options)
  let pathlist = map(
        \ copy(a:candidates),
        \ 'gina#util#fnameescape(gina#util#relpath(v:val.path))',
        \)
  execute printf(
        \ 'Gina reset --quiet -- %s',
        \ join(pathlist),
        \)
endfunction

function! s:on_checkout(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let git = gina#core#get_or_fail()
  let options = extend({
        \ 'force': 0,
        \ 'ours': 0,
        \ 'theirs': 0,
        \}, a:options)
  let params = gina#util#params('%')
  let revision = get(options, 'revision', get(params, 'revision', ''))
  let pathlist = map(
        \ copy(a:candidates),
        \ 'gina#util#fnameescape(gina#util#relpath(v:val.path))',
        \)
  execute printf(
        \ 'Gina! checkout --quiet %s %s %s %s -- %s',
        \ options.force ? '--force' : '',
        \ options.ours ? '--ours' : '',
        \ options.theirs ? '--theirs' : '',
        \ gina#util#shellescape(revision),
        \ join(pathlist),
        \)
endfunction

function! s:on_stage(candidates, options) abort dict
  if empty(a:candidates)
    return
  endif
  let rm_candidates = []
  let add_candidates = []
  for candidate in a:candidates
    if candidate.sign =~# '^.D$'
      call add(rm_candidates, candidate)
    elseif candidate.sign !~# '^. $'
      call add(add_candidates, candidate)
    endif
  endfor
  if get(a:options, 'force')
    call self.call('index:add:force', add_candidates)
    call self.call('index:rm:force', rm_candidates)
  else
    call self.call('index:add', add_candidates)
    call self.call('index:rm', rm_candidates)
  endif
endfunction

function! s:on_unstage(candidates, options) abort dict
  call self.call('index:reset', a:candidates)
endfunction

function! s:on_toggle(candidates, options) abort dict
  if empty(a:candidates)
    return
  endif
  let stage_candidates = []
  let unstage_candidates = []
  for candidate in a:candidates
    if candidate.sign =~# '^\%(??\|!!\|.\w\)$'
      call add(stage_candidates, candidate)
    elseif candidate.sign =~# '^\w.$'
      call add(unstage_candidates, candidate)
    endif
  endfor
  call self.call('index:stage', stage_candidates)
  call self.call('index:unstage', unstage_candidates)
endfunction

function! s:on_discard(candidates, options) abort dict
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'force': 0,
        \}, a:options)
  let delete_candidates = []
  let checkout_candidates = []
  for candidate in a:candidates
    if candidate.sign =~# '^\%(??\|!!\)$'
      call add(delete_candidates, candidate)
    else
      call add(checkout_candidates, candidate)
    endif
  endfor
  if !options.force
    call s:Console.warn(join([
          \ 'A discard action will discard all local changes on the working ',
          \ 'tree and the operation is irreversible, mean that you have no ',
          \ 'chance to revert the operation.',
          \], "\n"))
    call s:Console.info(
          \ 'This operation will be performed to the following candidates:'
          \)
    for candidate in extend(copy(delete_candidates), checkout_candidates)
      echo '- ' . s:Path.relpath(candidate.path)
    endfor
    if !s:Console.confirm('Are you sure to discard the changes?')
      return
    endif
  endif
  " delete untracked files
  for candidate in delete_candidates
    if isdirectory(candidate.path)
      call s:File.rmdir(candidate.path, 'r')
    elseif filewritable(candidate.path)
      call delete(candidate.path)
    endif
  endfor
  call self.call('index:checkout:HEAD:force', checkout_candidates)
  if !empty(delete_candidates) && empty(checkout_candidates)
    call gina#core#emitter#emit('modified:delay')
  endif
endfunction
