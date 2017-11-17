let s:KEYWORDS = [
      \ 'author-mail',
      \ 'author-time',
      \ 'author-tz',
      \ 'author',
      \ 'committer-mail',
      \ 'committer-time',
      \ 'committer-tz',
      \ 'committer',
      \ 'summary',
      \ 'previous',
      \ 'filename',
      \ 'boundary',
      \]
call map(
      \ s:KEYWORDS,
      \ '[v:val, len(v:val), substitute(v:val, ''-'', ''_'', ''g'')]',
      \)

function! gina#command#blame#pipe#incremental() abort
  let parser_pipe = deepcopy(s:parser_pipe)
  let parser_pipe.revisions = {}
  let parser_pipe.chunks = []
  let parser_pipe._stderr = []
  let parser_pipe._chunk = {}
  let parser_pipe._previous = ''
  return parser_pipe
endfunction


" Parser pipe ----------------------------------------------------------------
let s:parser_pipe = gina#util#inherit(gina#process#pipe#store())

function! s:parser_pipe.on_stdout(job, msg, event) abort
  if len(a:msg) <= 1
    let self._previous .= get(a:msg, 0, '')
    return
  endif
  let content = [self._previous . a:msg[0]] + a:msg[1:-2]
  let self._previous = a:msg[-1]
  call map(content, 'self.parse(v:val)')
endfunction

function! s:parser_pipe.on_exit(job, msg, event) abort
  if a:msg == 0
    if !empty(self._previous)
      call self.parse(self._previous)
    endif
    call sort(self.chunks, function('s:compare_chunks'))
    call map(self.chunks, 'extend(v:val, {''index'': v:key})')
  endif
  call self.super(s:parser_pipe, 'on_exit', a:job, a:msg, a:event)
endfunction

function! s:parser_pipe.parse(record) abort
  let chunk = self._chunk
  let revisions = self.revisions
  call extend(chunk, s:parse_record(a:record))
  if !has_key(chunk, 'filename')
    return
  endif
  if !has_key(revisions, chunk.revision)
    let revisions[chunk.revision] = chunk
    let chunk = {
          \ 'filename': chunk.filename,
          \ 'revision': chunk.revision,
          \ 'lnum_from': chunk.lnum_from,
          \ 'lnum': chunk.lnum,
          \ 'nlines': chunk.nlines,
          \}
  endif
  call add(self.chunks, chunk)
  let self._chunk = {}
endfunction


" Private --------------------------------------------------------
function! s:parse_record(record) abort
  for [prefix, length, vname] in s:KEYWORDS
    if a:record[:length-1] ==# prefix
      return {vname : a:record[length+1:]}
    endif
  endfor
  let terms = split(a:record)
  let nterms = len(terms)
  if nterms >= 3
    return {
          \ 'revision': terms[0],
          \ 'lnum_from': terms[1] + 0,
          \ 'lnum': terms[2] + 0,
          \ 'nlines': nterms == 3 ? 1 : (terms[3] + 0),
          \}
  endif
  throw gina#core#exception#critical(printf(
        \ 'Failed to parse a record "%s"',
        \ a:record,
        \))
endfunction

function! s:compare_chunks(lhs, rhs) abort
  return a:lhs.lnum - a:rhs.lnum
endfunction
