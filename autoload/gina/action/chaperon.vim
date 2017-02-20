function! gina#action#chaperon#define(binder) abort
  let description = 'Solve confict by chaperon'
  call a:binder.define('chaperon', function('s:on_chaperon'), {
        \ 'description': description,
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path', 'sign'],
        \ 'options': {},
        \})
  call a:binder.define('chaperon:above', function('s:on_chaperon'), {
        \ 'description': description,
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path', 'sign'],
        \ 'options': { 'opener': 'leftabove new' },
        \})
  call a:binder.define('chaperon:below', function('s:on_chaperon'), {
        \ 'description': description,
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path', 'sign'],
        \ 'options': { 'opener': 'belowright new' },
        \})
  call a:binder.define('chaperon:left', function('s:on_chaperon'), {
        \ 'description': description,
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path', 'sign'],
        \ 'options': { 'opener': 'leftabove vnew' },
        \})
  call a:binder.define('chaperon:right', function('s:on_chaperon'), {
        \ 'description': description,
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path', 'sign'],
        \ 'options': { 'opener': 'belowright vnew' },
        \})
  call a:binder.define('chaperon:tab', function('s:on_chaperon'), {
        \ 'description': description,
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path', 'sign'],
        \ 'options': { 'opener': 'tabedit' },
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:on_chaperon(candidates, options) abort
  let candidates = filter(copy(a:candidates), 'v:val.sign ==# ''UU''')
  if empty(candidates)
    return
  endif
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  for candidate in candidates
    execute printf(
          \ 'Gina chaperon %s %s %s -- %s',
          \ gina#util#shellescape(options.opener, '--opener='),
          \ gina#util#shellescape(get(candidate, 'line'), '--line='),
          \ gina#util#shellescape(get(candidate, 'col'), '--col='),
          \ gina#util#shellescape(candidate.path),
          \)
  endfor
endfunction
