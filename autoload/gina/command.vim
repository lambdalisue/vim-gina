let s:Argument = vital#gina#import('Argument')
let s:Config = vital#gina#import('Config')
let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Guard = vital#gina#import('Vim.Guard')
let s:Queue = vital#gina#import('Data.Queue')

let s:t_number = type(0)
let s:custom = {}

function! gina#command#call(git, args) abort
  if get(get(a:args, 'params', {}), 'async')
    call s:async_call(a:git, a:args)
  else
    call s:sync_call(a:git, a:args)
  endif
endfunction

function! gina#command#parse(qargs) abort
  let args = s:Argument.new(a:qargs)
  let scheme = substitute(args.get(0), '\W', '_', 'g')
  let custom = s:get_custom(scheme)
  for [query, value, remover] in custom
    if remover isnot# v:null && args.has(remover)
      call args.pop(remover)
      call args.pop(query)
    elseif !args.has(query)
      call args.set(query, value)
    endif
  endfor
  return args
endfunction

function! gina#command#custom(scheme, query, ...) abort
  let value = get(a:000, 0, 1)
  let remover = get(a:000, 1, v:null)
  if a:query !~# '^--\?\S\+\%(|--\?\S\+\)*$'
    throw 'gina: Invalid query has specified.'
  endif
  if type(value) == s:t_number && remover is v:null
    let remover = join(map(
          \ split(a:query, '|'),
          \ 's:build_remover_term(v:val)'
          \), '|')
  endif
  let scheme = substitute(a:scheme, '\W', '_', 'g')
  let custom = s:get_custom(scheme)
  call add(custom, [a:query, value, remover])
endfunction


" Private --------------------------------------------------------------------
function! s:build_remover_term(term) abort
  if a:term =~# '^--'
    return '--no-' . matchstr(a:term, '^--\zs\S\+')
  else
    return '-!' . matchstr(a:term, '^-\zs\S\+')
  endif
endfunction

function! s:sync_call(git, args) abort
  let result = gina#process#call(a:git, a:args)
  if result.status
    throw gina#process#error(result)
  endif
  let options = s:Buffer.parse_cmdarg()
  let options.lockmarks = 1
  call s:Buffer.edit_content(result.content, options)
endfunction

function! s:async_call(git, args) abort
  " Remove buffer content
  let guard = s:Guard.store(['&l:modifiable'])
  try
    setlocal modifiable
    silent lockmarks keepjumps %delete _
  finally
    call guard.restore()
  endtry
  " Start a new process
  let stream = gina#process#open(a:git, a:args, copy(s:stream))
  let stream._bufnr = bufnr('%')
  let stream._queue = s:Queue.new()
  let stream._start = reltime()
  let stream._args = a:args.raw
  let stream._timer = timer_start(
        \ g:gina#command#async_update_time,
        \ 's:stream_callback',
        \ { 'repeat': -1 }
        \)
  let s:streams[stream._timer] = stream
  return stream
endfunction

function! s:get_custom(scheme) abort
  if !exists('s:custom_' . a:scheme)
    let s:custom_{a:scheme} = []
  endif
  return s:custom_{a:scheme}
endfunction


" Stream ---------------------------------------------------------------------
let s:stream = {}
let s:streams = {}

function! s:stream.on_stdout(job, msg, event) abort
  call self._queue.put(a:msg)
endfunction

function! s:stream.on_stderr(job, msg, event) abort
  call self.on_stdout(a:job, a:msg, a:event)
endfunction

function! s:stream.on_timer() abort
  let msg = self._queue.get()
  if msg is# v:null
    if self.status() ==# 'dead'
      call self.close()
    endif
  else
    call self.flush(msg)
  endif
endfunction

function! s:stream.flush(msg) abort
  let focus = gina#util#buffer#focus(self._bufnr)
  if empty(focus) || bufnr('%') != self._bufnr
    return self.close()
  endif
  let guard = s:Guard.store(['&l:modifiable'])
  let view = winsaveview()
  try
    setlocal modifiable
    let leading = getline('$')
    let content = [leading . get(a:msg, 0, '')] + a:msg[1:]
    silent lockmarks keepjumps $delete _
    silent call s:Buffer.read_content(content, {
          \ 'edit': 1,
          \ 'line': '$',
          \ 'lockmarks': 1,
          \})
    if empty(getline(1))
      silent lockmarks keepjumps 1delete _
    endif
  finally
    call winrestview(view)
    call guard.restore()
    call focus.restore()
  endtry
endfunction

function! s:stream.close() abort
  silent! unlet s:streams[self._timer]
  silent! call timer_stop(self._timer)
  silent! call self.stop()
  let focus = gina#util#buffer#focus(self._bufnr)
  if empty(focus) || bufnr('%') != self._bufnr
    return
  endif
  let guard = s:Guard.store(['&l:modifiable'])
  let view = winsaveview()
  try
    setlocal modifiable
    if empty(getline('$'))
      silent lockmarks keepjumps $delete _
    endif
    setlocal nomodified
  finally
    call winrestview(view)
    call guard.restore()
    call focus.restore()
  endtry
endfunction

function! s:stream_callback(timer) abort
  let stream = get(s:streams, a:timer, v:null)
  if stream is# v:null
    return
  endif
  call stream.on_timer()
endfunction


call s:Config.define('g:gina#command', {
      \ 'async_update_time': 10
      \})
