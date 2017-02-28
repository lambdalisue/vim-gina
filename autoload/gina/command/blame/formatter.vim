scriptencoding utf-8
let s:String = vital#gina#import('Data.String')

let s:CURRENT_MARK = '▌'
let s:N_COLORS = 16


function! gina#command#blame#formatter#new(width, current, revisions) abort
  let formatter = deepcopy(s:formatter)
  let formatter._width = a:width
  let formatter._current = empty(a:current) ? 'X' : a:current
  let formatter._revisions = s:index_revisions(a:revisions)
  let formatter._previous = 1
  let formatter._timestamper = gina#command#blame#timestamper#new()
  let formatter._cache = {}
  return formatter
endfunction


" Private --------------------------------------------------------------------
function! s:index_revisions(revisions) abort
  let n = s:calc_nindicators(a:revisions)
  let revisions = deepcopy(a:revisions)
  let keys = keys(revisions)
  for index in range(len(revisions))
    let revisions[keys[index]].index = s:String.pad_left(
          \ s:String.nr2hex(index), n, '0'
          \)
  endfor
  return revisions
endfunction

function! s:calc_nindicators(revisions) abort
  let n = len(a:revisions)
  let x = 1
  while pow(s:N_COLORS, x) < n
    let x+= 1
  endwhile
  return x
endfunction


" Formatter ------------------------------------------------------------------
let s:formatter = {}

function! s:formatter.format(chunk) abort
  let revision = a:chunk.revision
  let revinfo = self._revisions[revision]
  let content = repeat(
        \ [self._format_line(a:chunk, revision, revinfo)],
        \ a:chunk.nlines,
        \)
  " Fill missing lines from previous
  let mlines = a:chunk.lnum - self._previous
  let self._previous = a:chunk.lnum + a:chunk.nlines
  return repeat([''], mlines) + content
endfunction

function! s:formatter._format_line(chunk, revision, revinfo) abort
  if has_key(self._cache, a:revision)
    return self._cache[a:revision]
  endif
  let mark = a:revision =~# '^' . self._current ? s:CURRENT_MARK : ' '
  let timestamp = 'on ' . self._timestamper.format(
        \ a:revinfo.author_time,
        \ a:revinfo.author_tz
        \)
  let suffix = join([timestamp, mark . a:revinfo.index])
  let width = self._width - strwidth(suffix) - 1
  let summary = s:String.truncate_skipping(
        \ a:revinfo.summary, width, 3,
        \ g:gina#command#blame#formatter#separator,
        \)
  let summary = s:String.pad_right(summary, width)
  let self._cache[a:revision] = join([summary, suffix])
  return self._cache[a:revision]
endfunction


" Config ---------------------------------------------------------------------
call gina#config(expand('<sfile>'), {
      \ 'separator': '⋯',
      \})
