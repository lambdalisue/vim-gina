function! gina#action#show#define(binder) abort
  let params = {
        \ 'description': 'Show the commit or a content at the commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \}
  call a:binder.define('show', function('s:on_show'), extend({
        \ 'options': {},
        \}, params))
  call a:binder.define('show:above', function('s:on_show'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'leftabove new'},
        \}, params))
  call a:binder.define('show:below', function('s:on_show'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'belowright new'},
        \}, params))
  call a:binder.define('show:left', function('s:on_show'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'leftabove vnew'},
        \}, params))
  call a:binder.define('show:right', function('s:on_show'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'belowright vnew'},
        \}, params))
  call a:binder.define('show:tab', function('s:on_show'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'tabedit'},
        \}, params))

  let params = {
        \ 'description': 'Show the commit',
        \ 'mapping_mode': 'n',
        \ 'requirements': [],
        \}
  call a:binder.define('show:commit', function('s:on_commit'), extend({
        \ 'options': {},
        \}, params))
  call a:binder.define('show:commit:above', function('s:on_commit'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'leftabove new'},
        \}, params))
  call a:binder.define('show:commit:below', function('s:on_commit'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'belowright new'},
        \}, params))
  call a:binder.define('show:commit:left', function('s:on_commit'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'leftabove vnew'},
        \}, params))
  call a:binder.define('show:commit:right', function('s:on_commit'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'belowright vnew'},
        \}, params))
  call a:binder.define('show:commit:tab', function('s:on_commit'), extend({
        \ 'hidden': 1,
        \ 'options': {'opener': 'tabedit'},
        \}, params))
endfunction


" Private --------------------------------------------------------------------
function! s:on_show(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  for candidate in a:candidates
    let treeish = gina#core#treeish#build(
          \ gina#util#get(candidate, 'rev'),
          \ gina#util#get(candidate, 'path', v:null),
          \)
    execute printf(
          \ 'Gina show %s %s %s %s -- %s',
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(get(candidate, 'line'), '--line='),
          \ gina#util#shellescape(get(candidate, 'col'), '--col='),
          \ gina#util#shellescape(treeish),
          \ gina#util#shellescape(gina#util#get(candidate, 'residual')),
          \)
  endfor
endfunction

function! s:on_commit(candidates, options) abort
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  for candidate in a:candidates
    let treeish = gina#core#treeish#build(
          \ gina#util#get(candidate, 'rev'),
          \ v:null
          \)
    execute printf(
          \ 'Gina show %s %s %s %s -- %s',
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(get(candidate, 'line'), '--line='),
          \ gina#util#shellescape(get(candidate, 'col'), '--col='),
          \ gina#util#shellescape(treeish),
          \ gina#util#shellescape(gina#util#get(candidate, 'residual')),
          \)
  endfor
endfunction
