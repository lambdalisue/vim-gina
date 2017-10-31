let s:t_number = type(0)
let s:RETRY_DELAY = 100
let s:RETRY_NUMBER = 15
let s:READ_THRESHOLD = 0.01

function! s:_vital_loaded(V) abort
  let s:Guard = a:V.import('Vim.Guard')
  let s:Queue = a:V.import('Data.Queue')
  let s:String = a:V.import('Data.String')
  let s:Window = a:V.import('Vim.Window')
  let s:exiting = 0
  augroup vital_vim_buffer_writer_{s:_SID()}
    autocmd! *
    autocmd VimLeave * let s:exiting = 1
  augroup END
endfunction

function! s:_vital_depends() abort
  return ['Vim.Guard', 'Data.Queue', 'Data.String', 'Vim.Window']
endfunction

function! s:_vital_created(module) abort
  let a:module.updatetime = 100
endfunction

function! s:_iconv(bufnr, text) abort
  let fileencoding = getbufvar(a:bufnr, '&fileencoding')
  if fileencoding ==# ''
    return a:text
  endif
  let expr = join(a:text, "\n")
  let result = s:String.iconv(expr, fileencoding, &encoding)
  return split(result, '\n', 1)
endfunction

" s:setbufline(expr, lnum, text)
if exists('*setbufline')
  " https://github.com/vim-jp/issues/issues/1080
  function! s:setbufline(expr, lnum, text) abort
    let foldmethod = getbufvar(a:expr, '&foldmethod')
    try
      call setbufvar(a:expr, '&foldmethod', 'manual')
      call setbufline(a:expr, a:lnum, a:text)
    finally
      call setbufvar(a:expr, '&foldmethod', foldmethod)
    endtry
  endfunction
elseif exists('*nvim_buf_set_lines')
  function! s:setbufline(expr, lnum, text) abort
    let bufnr = type(a:expr) == s:t_number ? a:expr : bufnr(a:expr)
    let start = a:lnum ==# '$' ? -2 : a:lnum
    return nvim_buf_set_lines(bufnr, start, -1, v:false, a:text)
  endfunction
else
  function! s:setbufline(expr, lnum, text) abort
    let focus = s:Window.focus_buffer(a:expr)
    try
      return setline(a:lnum, a:text)
    finally
      silent! call focus.restore()
    endtry
  endfunction
endif

" subbufline(expr, text)
if exists('*nvim_buf_set_lines')
  function! s:subbufline(expr, text) abort
    let bufnr = type(a:expr) == s:t_number ? a:expr : bufnr(a:expr)
    return nvim_buf_set_lines(bufnr, 0, -1, v:true, a:text)
  endfunction
else
  function! s:subbufline(expr, text) abort
    let focus = s:Window.focus_buffer(a:expr)
    try
      silent keepjumps %delete _
      return setline(1, a:text)
    finally
      silent! call focus.restore()
    endtry
  endfunction
endif

function! s:_assign_content(expr, text, retries, timer) abort
  if v:dying || s:exiting
    return
  elseif (a:retries > s:RETRY_NUMBER)
    throw printf(
          \ 'vital: Vim.Buffer.Writer: Failed to assign content of %s',
          \ bufname(a:expr),
          \)
  elseif !bufloaded(a:expr)
    call timer_start(
          \ s:RETRY_DELAY,
          \ function('s:_assign_content', [a:expr, a:text, a:retries + 1])
          \)
    return
  endif
  let modifiable = getbufvar(a:expr, '&modifiable')
  try
    call setbufvar(a:expr, '&modifiable', 1)
    call s:subbufline(a:expr, a:text)
  catch /^Vim\%((\a\+)\)\=:E523/  " Not allowed here
    " Retry a bit later while Vim raise E523 when the buffer is not ready
    call timer_start(
          \ s:RETRY_DELAY,
          \ function('s:_assign_content', [a:expr, a:text, a:retries + 1])
          \)
  finally
    call setbufvar(a:expr, '&modifiable', modifiable)
  endtry
endfunction

function! s:assign_content(expr, text) abort
  let bufnr = a:expr is# v:null ? bufnr('%') : bufnr(a:expr)
  let text = s:_iconv(bufnr, a:text)
  call call('s:_assign_content', [bufnr, text, 0, v:null])
endfunction

function! s:_extend_content(expr, text, retries, timer) abort
  if v:dying || s:exiting || empty(a:text)
    return
  elseif (a:retries > s:RETRY_NUMBER)
    throw printf(
          \ 'vital: Vim.Buffer.Writer: Failed to extend content of %s',
          \ bufname(a:expr),
          \)
  elseif !bufloaded(a:expr)
    call timer_start(
          \ s:RETRY_DELAY,
          \ function('s:_extend_content', [a:expr, a:text, a:retries + 1])
          \)
    return
  endif

  let modifiable = getbufvar(a:expr, '&modifiable')
  try
    let leading = getbufline(a:expr, '$')
    let leading[0] .= a:text[0]
    call setbufvar(a:expr, '&modifiable', 1)
    call s:setbufline(a:expr, '$', leading + a:text[1:])
  catch /^Vim\%((\a\+)\)\=:E523/  " Not allowed here
    " Retry a bit later while Vim raise E523 when the buffer is not ready
    call timer_start(
          \ s:RETRY_DELAY,
          \ function('s:_extend_content', [a:expr, a:text, a:retries + 1])
          \)
  finally
    call setbufvar(a:expr, '&modifiable', modifiable)
  endtry
endfunction

function! s:extend_content(expr, text) abort
  let bufnr = a:expr is# v:null ? bufnr('%') : bufnr(a:expr)
  let text = s:_iconv(bufnr, a:text)
  call call('s:_extend_content', [bufnr, text, 0, v:null])
endfunction

function! s:new(...) abort dict
  let options = extend({
        \ 'bufnr': bufnr('%'),
        \ 'updatetime': self.updatetime,
        \}, get(a:000, 0, {})
        \)
  let writer = extend(copy(s:writer), options)
  let writer._queue = s:Queue.new()
  return writer
endfunction


" Writer instance ------------------------------------------------------------
let s:timers = {}
let s:writers = {}
let s:writer = {'_timer': v:null, '_running': 0}

function! s:_timer_callback(timer) abort
  let writer = get(s:timers, a:timer, v:null)
  if writer is# v:null
    call timer_stop(a:timer)
    unlet s:timers[a:timer]
    return
  endif
  call writer.flush()
endfunction

function! s:writer.start() abort
  if self._timer isnot# v:null
    return
  endif
  lockvar! self.bufnr
  lockvar! self.updatetime
  " Kill previous writer which target a same buffer before start
  if has_key(s:writers, self.bufnr)
    call s:writers[self.bufnr].kill()
    call self.clear()
  endif
  let s:writers[self.bufnr] = self
  let self._running = 1
  let self._timer = timer_start(
        \ self.updatetime,
        \ function('s:_timer_callback'),
        \ {'repeat': -1}
        \)
  let s:timers[self._timer] = self
  call self.on_start()
endfunction

function! s:writer.stop() abort
  " Now writer is going to stop
  let self._running = 0
endfunction

function! s:writer.kill() abort
  silent! call timer_stop(self._timer)
  silent! unlet s:timers[self._timer]
  let self._running = 0
  unlockvar! self.bufnr
  unlockvar! self.updatetime
  call self.on_stop()
endfunction

function! s:writer.clear() abort
  call s:assign_content(self.bufnr, [])
  call self.on_clear()
endfunction

function! s:writer.write(msg) abort
  call self._queue.put(a:msg)
  call self.on_write(a:msg)
endfunction

function! s:writer.read() abort
  let chunk = self._queue.get()
  if chunk is# v:null
    return v:null
  endif
  let content = copy(chunk)
  let start = reltime()
  while reltimefloat(reltime(start)) < s:READ_THRESHOLD
    let chunk = self._queue.get()
    if chunk is# v:null
      break
    endif
    let content[-1] .= chunk[0]
    call extend(content, chunk[1:])
  endwhile
  return self.on_read(content)
endfunction

function! s:writer.flush() abort
  if bufwinnr(self.bufnr) == -1
    return
  endif
  let msg = self.read()
  if msg is# v:null && !self._running
    " No left over content and the writer is going to stop
    " so kill the writer to stop
    return self.kill()
  endif
  try
    call s:extend_content(self.bufnr, msg)
    call self.on_flush(msg)
  catch
    call self.kill()
  endtry
endfunction

function! s:writer.on_start() abort
  " User can override this method
endfunction

function! s:writer.on_clear() abort
  " User can override this method
endfunction

function! s:writer.on_write(msg) abort
  " User can override this method
endfunction

function! s:writer.on_read(msg) abort
  return a:msg
endfunction

function! s:writer.on_flush(msg) abort
  " User can override this method
endfunction

function! s:writer.on_stop() abort
  " User can override this method
endfunction
