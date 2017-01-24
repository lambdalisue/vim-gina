function! gina#action#show#define(binder, ...) abort
  call a:binder.define('show', function('s:on_show'), {
        \ 'description': 'Open and show a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': {},
        \})
  call a:binder.define('show:above', function('s:on_show'), {
        \ 'description': 'Open and show a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'leftabove new' },
        \})
  call a:binder.define('show:below', function('s:on_show'), {
        \ 'description': 'Open and show a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'belowright new' },
        \})
  call a:binder.define('show:left', function('s:on_show'), {
        \ 'description': 'Open and show a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'leftabove vnew' },
        \})
  call a:binder.define('show:right', function('s:on_show'), {
        \ 'description': 'Open and show a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'belowright vnew' },
        \})
  call a:binder.define('show:tab', function('s:on_show'), {
        \ 'description': 'Open and show a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'tabedit' },
        \})
  call a:binder.define('show:preview', function('s:on_show'), {
        \ 'description': 'Open and show a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \ 'options': { 'opener': 'pedit' },
        \})

  if get(a:000, 0, 0)
    call gina#action#alias('above', 'show:above')
    call gina#action#alias('below', 'show:below')
    call gina#action#alias('left', 'show:left')
    call gina#action#alias('right', 'show:right')
    call gina#action#alias('tab', 'show:tab')
    call gina#action#alias('preview', 'show:preview')
  endif
endfunction


" Private --------------------------------------------------------------------
function! s:on_show(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let git = gina#core#get_or_fail()
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  let params = gina#util#params('%')
  let path = get(params, 'path', '')
  let commit = get(params, 'commit', '')
  for candidate in a:candidates
    execute printf(
          \ 'Gina show %s %s %s %s -- %s',
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(get(candidate, 'line'), '--line='),
          \ gina#util#shellescape(get(candidate, 'col'), '--col='),
          \ gina#util#shellescape(get(candidate, 'commit', commit)),
          \ gina#util#fnameescape(get(candidate, 'path', path)),
          \)
  endfor
endfunction
