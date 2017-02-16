let s:Guard = vital#gina#import('Vim.Guard')
let s:Queue = vital#gina#import('Data.Queue')
let s:timers = {}


function! gina#core#writer#new(...) abort
  let options = get(a:000, 0, {})
  let writer = extend(copy(s:writer), options)
  let writer._bufnr = bufnr('%')
  let writer._queue = s:Queue.new()
  let writer._winview = get(b:, 'gina_winview', winsaveview())
  return writer
endfunction


" Private --------------------------------------------------------------------
function! s:timer_callback(timer) abort
  let writer = get(s:timers, a:timer, v:null)
  if writer is# v:null
    call timer_stop(a:timer)
    return
  endif
  call writer.flush()
endfunction


" Writer ---------------------------------------------------------------------
let s:writer = {'_timer': v:null}

function! s:writer.start() abort
  if self._timer isnot# v:null
    return
  endif
  let self._timer = timer_start(
        \ g:gina#process#updatetime,
        \ function('s:timer_callback'),
        \ {'repeat': -1}
        \)
  let s:timers[self._timer] = self
  call self.on_start()
endfunction

function! s:writer.stop() abort
  silent! unlet s:timers[self._timer]
  silent! call timer_stop(self._timer)
  let self._timer = v:null
  let focus = gina#core#buffer#focus(self._bufnr)
  if empty(focus) || bufnr('%') != self._bufnr
    call self.on_stop()
    return
  endif
  let guard = s:Guard.store(['&l:modifiable'])
  try
    setlocal modifiable
    if empty(getline('$'))
      silent lockmarks keepjumps $delete _
    endif
    setlocal nomodified
  finally
    call winrestview(self._winview)
    call guard.restore()
    call focus.restore()
    call self.on_stop()
  endtry
endfunction

function! s:writer.clear() abort
  let focus = gina#core#buffer#focus(self._bufnr)
  if empty(focus) || bufnr('%') != self._bufnr
    return self.stop()
  endif
  let guard = s:Guard.store(['&l:modifiable'])
  try
    setlocal modifiable
    silent lockmarks keepjumps %delete _
  finally
    call guard.restore()
    call focus.restore()
    call self.on_clear()
  endtry
endfunction

function! s:writer.write(msg) abort
  call self._queue.put(a:msg)
  call self.on_write(a:msg)
endfunction

function! s:writer.flush() abort
  let msg = self._queue.get()
  if msg is# v:null
    if !self.on_check()
      call self.stop()
    endif
    return
  endif
  let focus = gina#core#buffer#focus(self._bufnr)
  if empty(focus) || bufnr('%') != self._bufnr
    return self.stop()
  endif
  let guard = s:Guard.store(['&l:modifiable'])
  let view = winsaveview()
  try
    setlocal modifiable
    call gina#core#buffer#extend_content(msg)
  finally
    call winrestview(view)
    call guard.restore()
    call focus.restore()
    call self.on_flush(msg)
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

function! s:writer.on_flush(msg) abort
  " User can override this method
endfunction

function! s:writer.on_check() abort
  " User can override this method
  return 1
endfunction

function! s:writer.on_stop() abort
  " User can override this method
endfunction



" Automatically update b:gina_winview with cursor move while no buffer content
" is available in BufReadCmd and winsaveview() always returns unwilling value
augroup gina_core_writer_internal
  autocmd! *
  autocmd CursorMoved  gina://* let b:gina_winview = winsaveview()
  autocmd CursorMovedI gina://* let b:gina_winview = winsaveview()
augroup END
