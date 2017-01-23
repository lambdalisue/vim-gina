let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Console = vital#gina#import('Vim.Console')
let s:Guard = vital#gina#import('Vim.Guard')
let s:Emitter = vital#gina#import('Emitter')


function! gina#command#call(git, args, ...) abort
  let options = get(a:000, 0, {})
  let result = gina#process#call(a:git, a:args.raw, options)
  call gina#process#inform(result)
  call s:Emitter.emit('gina:modified')
  return result
endfunction


" Pipe -----------------------------------------------------------------------
let s:stream = {}

function! s:stream.on_stdout(job, msg, event) abort
  let focus = gina#util#buffer#focus(self.__bufnr)
  if empty(focus)
    return self.stop()
  endif
  if get(b:, 'gina_job') isnot# self
    return self.stop()
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
          \ 'lockmarks': 1,
          \})
    if empty(getline(1))
      silent lockmarks keepjumps 1delete _
    endif
    call s:Emitter.emit('gina:stream:out', a:job, a:msg, a:event)
  finally
    call winrestview(view)
    call guard.restore()
    call focus.restore()
  endtry
endfunction

function! s:stream.on_stderr(job, msg, event) abort
  call self.on_stdout(a:job, a:msg, a:event)
endfunction

function! s:stream.on_exit(job, msg, event) abort
  let focus = gina#util#buffer#focus(self.__bufnr)
  if empty(focus)
    return
  endif
  if get(b:, 'gina_job') isnot# self
    return
  endif
  let guard = s:Guard.store(['&l:modifiable'])
  try
    setlocal modifiable
    if empty(getline('$'))
      silent lockmarks keepjumps $delete _
    endif
    setlocal nomodified
    call s:Emitter.emit('gina:stream:exit', a:job, a:msg, a:event)
  finally
    call winrestview(self.__winview)
    call guard.restore()
    call focus.restore()
  endtry
endfunction
