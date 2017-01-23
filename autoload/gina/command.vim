let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Console = vital#gina#import('Vim.Console')
let s:Guard = vital#gina#import('Vim.Guard')
let s:Emitter = vital#gina#import('Emitter')
let s:Queue = vital#gina#import('Data.Queue')


function! gina#command#call(git, args, ...) abort
  let options = get(a:000, 0, {})
  let result = gina#process#call(a:git, a:args.raw, options)
  call gina#process#inform(result)
  call s:Emitter.emit('gina:modified')
  return result
endfunction

function! gina#command#stream(git, args, ...) abort
  let options = extend(copy(s:stream), get(a:000, 0, {}))
  " Remove buffer content
  let guard = s:Guard.store(['&l:modifiable'])
  try
    setlocal modifiable
    silent lockmarks keepjumps %delete _
  finally
    call guard.restore()
  endtry
  " Start a new process
  let stream = gina#process#open(a:git, a:args.raw, options)
  let stream._bufnr = bufnr('%')
  let stream._queue = s:Queue.new()
  let stream._start = reltime()
  let stream._args = a:args.raw
  let stream._timer = timer_start(
        \ 100, 's:stream_callback', { 'repeat': -1 }
        \)
  let s:streams[stream._timer] = stream
  return stream
endfunction

" For Debug
function! gina#command#_print_streams() abort
  for stream in values(s:streams)
    echo printf('Stream [timer: %d]', stream._timer)
    echo printf('| time:   %s', reltimestr(reltime(stream._start)))
    echo printf('| args:   %s', join(stream._args))
    echo printf('| bufnr:  %d', stream._bufnr)
    echo printf('| count:  %d', len(stream._queue.__data))
    echo printf('| status: %s', stream.status())
  endfor
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
