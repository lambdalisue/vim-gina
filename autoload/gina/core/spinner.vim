scriptencoding utf-8

if $LANG == 'C'
  let s:frames = ['-', '\', '|', '/']
else
  let s:frames = ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷']
endif

function! gina#core#spinner#new(expr, ...) abort
  let options = extend({
        \ 'frames': s:frames,
        \ 'message': 'Loading ...',
        \ 'updatetime': 100,
        \}, a:0 ? a:1 : {})
  let spinner = deepcopy(s:spinner)
  let spinner._bufnr = bufnr(a:expr)
  let spinner._frames = options.frames
  let spinner._message = options.message
  let spinner._updatetime = options.updatetime
  return spinner
endfunction

function! gina#core#spinner#start(expr, ...) abort
  let spinner = gina#core#spinner#new(a:expr, a:0 ? a:1 : {})
  call spinner.start()
  return spinner
endfunction



let s:spinner = {
      \ '_timer': v:null,
      \ '_bufnr': 0,
      \ '_index': 0,
      \}

function! s:spinner.next() abort
  let index = self._index + 1
  let self._index = index >= len(self._frames) ? 0 : index
  return self._index
endfunction

function! s:spinner.text() abort
  let face = self._frames[self._index]
  return ' ' . face . ' ' . self._message
endfunction

function! s:spinner.start() abort
  if self._timer isnot# v:null
    return
  endif
  let self._statusline = getbufvar(self._bufnr, '&statusline')
  let self._timer = timer_start(
        \ self._updatetime,
        \ function('s:update_spinner', [self]),
        \ { 'repeat': -1 }
        \)
endfunction

function! s:spinner.stop() abort
  if self._timer is# v:null
    return
  endif
  call timer_stop(self._timer)
  call setbufvar(self._bufnr, '&statusline', self._statusline)
  let self._timer = v:null
endfunction

function! s:update_spinner(spinner, timer) abort
  if !bufexists(a:spinner._bufnr)
    call a:spinner.stop()
  elseif bufwinnr(a:spinner._bufnr) >= 0
    call a:spinner.next()
    call setbufvar(a:spinner._bufnr, '&statusline', a:spinner.text())
  endif
endfunction
