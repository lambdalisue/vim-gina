function! s:_vital_loaded(V) abort
  let s:Guard = a:V.import('Vim.Guard')
  let s:Queue = a:V.import('Data.Queue')
  let s:String = a:V.import('Data.String')
  let s:Window = a:V.import('Vim.Window')
endfunction

function! s:_vital_depends() abort
  return ['Vim.Guard', 'Data.Queue', 'Data.String', 'Vim.Window']
endfunction

function! s:_vital_created(module) abort
  let a:module.use_python = 1
  let a:module.use_python3 = 1
  let a:module.updatetime = 10
endfunction

function! s:new(...) abort dict
  let options = extend({
        \ 'bufnr': bufnr('%'),
        \ 'updatetime': self.updatetime,
        \}, get(a:000, 0, {})
        \)
  let writer = extend(copy(s:writer), options)
  let writer._queue = s:Queue.new()
  let writer._module = copy(self)
  lockvar writer._module
  return writer
endfunction


" Utility functions ----------------------------------------------------------
function! s:assign_content(bufnr, content) abort dict
  if a:bufnr isnot# v:null && bufwinnr(a:bufnr) < 1
    return 0
  endif
  let content = s:_iconv(a:bufnr, a:content)
  if a:bufnr is# v:null || a:bufnr == bufnr('%')
    call s:_assign_content(content)
    return 1
  elseif has('python3') && self.use_python3 && s:_ready_python3()
    call s:_assign_content_python3(a:bufnr, content)
    return 1
  elseif has('python') && self.use_python && s:_ready_python()
    call s:_assign_content_python(a:bufnr, content)
    return 1
  endif
  let focus = s:Window.focus_buffer(a:bufnr)
  try
    call s:_assign_content(content)
    return 1
  finally
    call focus.restore()
  endtry
  return 0
endfunction

if has('nvim')
  function! s:_assign_content_python3(bufnr, content) abort
python3 << EOC
def _vital_vim_bufferwriter_assign_content():
  content = vim.eval('a:content')
  vbuffer = vim.buffers[int(vim.eval('a:bufnr'))]
  modifiable = vbuffer.options['modifiable']
  vbuffer.options['modifiable'] = True
  try:
    vbuffer[:] = content
  finally:
    vbuffer.options['modifiable'] = modifiable
_vital_vim_bufferwriter_assign_content()
EOC
  endfunction
else
  " Vim's builtin python3 implementation does not handle Unicode well so
  " manually encode/decode from byte-stream (vim.bindeval)
  function! s:_assign_content_python3(bufnr, content) abort
python3 << EOC
def _vital_vim_bufferwriter_assign_content():
  encoding = vim.eval('&encoding')
  fileencoding = vim.eval('&fileencoding')
  content = vim.bindeval('a:content')  # vim.eval raise Unicode error
  vbuffer = vim.buffers[int(vim.eval('a:bufnr'))]
  modifiable = vbuffer.options['modifiable']
  vbuffer.options['modifiable'] = True
  try:
    vbuffer[:] = content[:]   # content[:] for vim.list -> list conversion
  finally:
    vbuffer.options['modifiable'] = modifiable
try:
  _vital_vim_bufferwriter_assign_content()
except Exception as e:
  vim.command('call themis#log(%s)' % str(e).splitlines())
EOC
  endfunction
endif

function! s:_assign_content_python(bufnr, content) abort
python << EOC
def _vital_vim_bufferwriter_assign_content():
  content = vim.eval('a:content')
  vbuffer = vim.buffers[int(vim.eval('a:bufnr'))]
  modifiable = vbuffer.options['modifiable']
  vbuffer.options['modifiable'] = True
  try:
    vbuffer[:] = content
  finally:
    vbuffer.options['modifiable'] = modifiable
_vital_vim_bufferwriter_assign_content()
EOC
endfunction

function! s:_assign_content(content) abort
  let guard = s:Guard.store(['&l:modifiable'])
  try
    setlocal modifiable
    silent keepjumps %delete _
    call setline(1, a:content)
  finally
    call guard.restore()
  endtry
endfunction


function! s:extend_content(bufnr, content) abort dict
  if a:bufnr isnot# v:null && bufwinnr(a:bufnr) < 1
    return 0
  elseif empty(a:content)
    return 1
  endif
  let content = s:_iconv(a:bufnr, a:content)
  if a:bufnr is# v:null || a:bufnr == bufnr('%')
    call s:_extend_content(content)
    return 1
  elseif has('python3') && self.use_python3 && s:_ready_python3()
    call s:_extend_content_python3(a:bufnr, content)
    return 1
  elseif has('python') && self.use_python && s:_ready_python()
    call s:_extend_content_python(a:bufnr, content)
    return 1
  endif
  let focus = s:Window.focus_buffer(a:bufnr)
  try
    call s:_extend_content(content)
    return 1
  finally
    call focus.restore()
  endtry
  return 0
endfunction

if has('nvim')
  function! s:_extend_content_python3(bufnr, content) abort
python3 << EOC
def _vital_vim_bufferwriter_extend_content():
  content = vim.eval('a:content')
  vbuffer = vim.buffers[int(vim.eval('a:bufnr'))]
  modifiable = vbuffer.options['modifiable']
  vbuffer.options['modifiable'] = True
  try:
    leading = vbuffer[-1] + content[0]
    del vbuffer[-1]
    initial = vbuffer[0] == '' and len(vbuffer) == 1
    vbuffer.append([leading] + content[1:])
    if initial:
      del vbuffer[0]
  finally:
    vbuffer.options['modifiable'] = modifiable
_vital_vim_bufferwriter_extend_content()
EOC
  endfunction
else
  function! s:_extend_content_python3(bufnr, content) abort
python3 << EOC
def _vital_vim_bufferwriter_extend_content():
  encoding = vim.eval('&encoding')
  content = vim.bindeval('a:content')
  vbuffer = vim.buffers[int(vim.eval('a:bufnr'))]
  modifiable = vbuffer.options['modifiable']
  vbuffer.options['modifiable'] = True
  try:
    leading = vbuffer[-1].encode(encoding, 'surrogateescape') + content[0]
    del vbuffer[-1]
    initial = vbuffer[0] == '' and len(vbuffer) == 1
    vbuffer.append([leading] + content[1:])
    if initial:
      del vbuffer[0]
  finally:
    vbuffer.options['modifiable'] = modifiable
_vital_vim_bufferwriter_extend_content()
EOC
  endfunction
endif

function! s:_extend_content_python(bufnr, content) abort
python << EOC
def _vital_vim_bufferwriter_extend_content():
  content = vim.eval('a:content')
  vbuffer = vim.buffers[int(vim.eval('a:bufnr'))]
  modifiable = vbuffer.options['modifiable']
  vbuffer.options['modifiable'] = True
  try:
    leading = vbuffer[-1] + content[0]
    del vbuffer[-1]
    initial = vbuffer[0] == '' and len(vbuffer) == 1
    vbuffer.append([leading] + content[1:])
    if initial:
      del vbuffer[0]
  finally:
    vbuffer.options['modifiable'] = modifiable
_vital_vim_bufferwriter_extend_content()
EOC
endfunction

function! s:_extend_content(content) abort
  let guard = s:Guard.store(['&l:modifiable'])
  try
    setlocal modifiable
    let leading = getline('$') . a:content[0]
    call setline(line('$'), [leading] + a:content[1:])
  catch /^Vim\%((\a\+)\)\=:E523/  " Not allowed here
    " Skip
  finally
    call guard.restore()
  endtry
endfunction


function! s:_ready_python() abort
  if exists('s:python_enabled')
    return s:python_enabled
  endif
  try
    python import vim
    let s:python_enabled = 1
  catch
    " python may not be linked correctly
    let s:python_enabled = 0
  endtry
  return s:python_enabled
endfunction

function! s:_ready_python3() abort
  if exists('s:python3_enabled')
    return s:python3_enabled
  endif
  try
    python3 import vim
    let s:python3_enabled = 1
  catch
    " python3 may not be linked correctly
    let s:python3_enabled = 0
  endtry
  return s:python3_enabled
endfunction

function! s:_iconv(bufnr, content) abort
  let fileencoding = a:bufnr is# v:null
        \ ? &fileencoding
        \ : getbufvar(a:bufnr, '&fileencoding')
  if fileencoding ==# ''
    return a:content
  endif
  let expr = join(a:content, "\n")
  let result = s:String.iconv(expr, fileencoding, &encoding)
  return split(result, '\n')
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
  call self._module.assign_content(self.bufnr, [])
  call self.on_clear()
endfunction

function! s:writer.write(msg) abort
  call self._queue.put(a:msg)
  call self.on_write(a:msg)
endfunction

function! s:writer.read() abort
  return self.on_read(self._queue.get())
endfunction

function! s:writer.flush() abort
  let msg = self.read()
  if msg is# v:null && !self._running
    " No left over content and the writer is going to stop
    " so kill the writer to stop
    return self.kill()
  endif
  if !self._module.extend_content(self.bufnr, msg)
    " The target buffer is missing so stop the writer immediately
    return self.kill()
  endif
  call self.on_flush(msg)
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
