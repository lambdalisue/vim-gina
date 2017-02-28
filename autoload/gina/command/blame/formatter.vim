scriptencoding utf-8
let s:String = vital#gina#import('Data.String')


function! gina#command#blame#formatter#new(width, current, revisions) abort
  let formatter = deepcopy(s:formatter)
  let formatter.width = a:width
  let formatter.current = a:current
  let formatter.revisions = a:revisions
  let formatter.timestamper = gina#command#blame#timestamper#new()
  let formatter._previous = 1
  let formatter._cache1 = {}
  let formatter._cache2 = {}
  let formatter._cache3 = {}
  let formatter._cache4 = {}
  return formatter
endfunction


" Formatter ------------------------------------------------------------------
let s:formatter = {}

function! s:formatter.format(chunk) abort
  let revision = a:chunk.revision
  let revinfo = self.revisions[revision]
  let nlines = a:chunk.nlines > 3 ? 4 : a:chunk.nlines
  if a:chunk.nlines == 1
    let content = self._format1(a:chunk, revision, revinfo)
  elseif a:chunk.nlines == 2
    let content = self._format2(a:chunk, revision, revinfo)
  elseif a:chunk.nlines == 3
    let content = self._format3(a:chunk, revision, revinfo)
  else
    let content = self._format4(a:chunk, revision, revinfo)
  endif
  " Fill missing lines from previous
  let mlines = a:chunk.lnum - self._previous
  let self._previous = a:chunk.lnum + a:chunk.nlines
  return repeat([''], mlines) + content
endfunction

" 03gft2g    @lambdalisue
function! s:formatter._format1(chunk, revision, revinfo) abort
  if has_key(self._cache1, a:revision)
    return self._cache1[a:revision]
  endif
  let length = self.width - 8
  let author = s:String.trim(s:String.truncate_skipping(
        \ '@' . a:revinfo.author,
        \ length - 1, 2,
        \ g:gina#command#blame#formatter#separator,
        \))
  if get(a:revinfo, 'boundary')
    let revision = '^' . a:revision[:6]
  elseif !empty(self.current)
        \ && a:revision =~# '^' . self.current
    if has_key(a:revinfo, 'previous')
      let revision = a:revision[:6] . '^'
    else
      let revision = '$' . a:revision[:6]
    endif
  else
    let revision = a:revision[:7]
  endif
  let content = [revision . s:String.pad_left(author, length)]
  let self._cache1[a:revision] = content
  retur content
endfunction

" 03gft2g    @lambdalisue
" Summary of the commit m
function! s:formatter._format2(chunk, revision, revinfo) abort
  if has_key(self._cache2, a:revision)
    return self._cache2[a:revision]
  endif
  let summary = s:String.truncate_skipping(
        \ a:revinfo.summary,
        \ self.width, 2,
        \ g:gina#command#blame#formatter#separator,
        \)
  let content = copy(self._format1(a:chunk, a:revision, a:revinfo))
  let content += [s:String.pad_right(summary, self.width)]
  let self._cache2[a:revision] = content
  return content
endfunction

" 03gft2g    @lambdalisue
" Summary of the commit m
" |            2 days ago
function! s:formatter._format3(chunk, revision, revinfo) abort
  if has_key(self._cache3, a:revision)
    return self._cache3[a:revision]
  endif
  let timestamp = self.timestamper.format(
        \ a:revinfo.author_time,
        \ a:revinfo.author_tz
        \)
  let content = copy(self._format2(a:chunk, a:revision, a:revinfo))
  let content += ['|' . s:String.pad_left(timestamp, self.width - 1)]
  let self._cache3[a:revision] = content
  return content
endfunction

" 03gft2g    @lambdalisue
" Summary of the commit m
" essage
" |
" |            2 days ago
function! s:formatter._format4(chunk, revision, revinfo) abort
  if has_key(self._cache4, a:revision)
    let summary = self._cache4[a:revision]
  else
    let summary = map(
          \ s:String.wrap(a:revinfo.summary, self.width),
          \ 's:String.pad_right(s:String.trim(v:val), self.width)',
          \)
    let self._cache4[a:revision] = summary
  endif
  let nlines = a:chunk.nlines - 2
  let content = copy(self._format3(a:chunk, a:revision, a:revinfo))
  call remove(content, 1)
  call extend(content, summary[:nlines-1], 1)
  call extend(content, repeat(['|'], nlines - len(content)), -1)
  return content
endfunction


" Config ---------------------------------------------------------------------
call gina#config(expand('<sfile>'), {
      \ 'separator': '⋯',
      \})
