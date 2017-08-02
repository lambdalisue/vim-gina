function! gina#action#utils#define(binder) abort
  call a:binder.define('utils:yank', function('s:on_yank'), {
        \ 'description': 'Yank the revision of candidate under the cursor',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': {},
        \ 'use_marks': 0,
        \ 'clear_marks': 0,
        \})
  call a:binder.define('utils:yank:path', function('s:on_yank'), {
        \ 'description': 'Yank the revision and path (if exists) of candidate under the cursor',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev'],
        \ 'options': {'path': 1},
        \ 'use_marks': 0,
        \ 'clear_marks': 0,
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_yank(candidates, options) abort dict
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'path': 0,
        \}, a:options)
  let candidate = a:candidates[0]
  let revision = gina#util#get(candidate, 'rev')
  if empty(revision)
    let revision = 'HEAD'
  endif
  if options.path
    let target = gina#core#treeish#build(
          \ revision,
          \ gina#util#get(candidate, 'path', v:null)
          \)
  else
    let target = revision
  endif
  call gina#util#yank(gina#util#shellescape(target))
endfunction

