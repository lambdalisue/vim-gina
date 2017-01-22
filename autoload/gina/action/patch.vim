function! gina#action#patch#define(binder) abort
  call a:binder.define('patch', function('s:on_patch'), {
        \ 'description': 'Patch a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': {},
        \})
  call a:binder.define('patch:above', function('s:on_patch'), {
        \ 'description': 'Patch a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'leftabove new' },
        \})
  call a:binder.define('patch:below', function('s:on_patch'), {
        \ 'description': 'Patch a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'belowright new' },
        \})
  call a:binder.define('patch:left', function('s:on_patch'), {
        \ 'description': 'Patch a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'leftabove vnew' },
        \})
  call a:binder.define('patch:right', function('s:on_patch'), {
        \ 'description': 'Patch a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'belowright vnew' },
        \})
  call a:binder.define('patch:tab', function('s:on_patch'), {
        \ 'description': 'Patch a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'tabedit' },
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_patch(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let git = gina#core#get_or_fail()
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  let params = gina#util#params('%')
  let path = get(params, 'path', '')
  for candidate in a:candidates
    let selection = get(candidate, 'selection', [])
    execute printf(
          \ 'Gina patch %s %s -- %s',
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(
          \   gina#util#selection#format(selection),
          \   '--selection='
          \ ),
          \ gina#util#fnameescape(get(candidate, 'path', path)),
          \)
  endfor
endfunction
