function! s:format_locus(locus) abort
  let line = get(a:locus, 0, line('.'))
  let col = get(a:locus, 1, col('.'))
  return printf('%d:%d', line, col)
endfunction

function! s:format_selection(selection) abort
  let start = get(a:selection, 0, [])
  let end = get(a:selection, 0, start)
  return printf('%s-%s', s:format_locus(start), s:format_locus(end))
endfunction

function! s:parse_locus(expr) abort
  let line = matchstr(a:expr, '^\d\+')
  let col = matchstr(a:expr, '^\d\+:\zs\d\+')
  return [str2nr(line), str2nr(empty(col) ? line : col)]
endfunction

function! s:parse_selection(expr) abort
  let start = matchstr(a:expr, '^[0-9:]\+')
  let end = matchstr(a:expr, '^[0-9:]\+-\zs[0-9:]\+')
  return [s:parse_locus(start), s:parse_locus(empty(end) ? start : end)]
endfunction

" Original from mattn/emmet-vim
" https://github.com/mattn/emmet-vim/blob/master/autoload/emmet/util.vim#L75-L79
function! s:set_current_selection(selection, ...) abort
  let options = extend({
        \ 'prefer_visual': 0,
        \}, get(a:000, 0, {})
        \)
  let s = get(a:selection, 0, [line('.'), col('.')])
  let e = get(a:selection, 1, s)
  if s == e && !options.prefer_visual
    call setpos('.', [0, s[0], s[1], 0])
  else
    call setpos('.', [0, e[0], e[1], 0])
    keepjumps normal! v
    call setpos('.', [0, s[0], s[1], 0])
  endif
endfunction

function! s:get_current_selection() abort
  let is_visualmode = mode() =~# '^\c\%(v\|CTRL-V\|s\)$'
  let selection = is_visualmode
        \ ? [[line("'<"), col("'<")], [line("'>"), col("'>")]]
        \ : [[line('.'), col('.')], [line('.'), col('.')]]
  return selection
endfunction
