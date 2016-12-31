function! s:_vital_loaded(V) abort
  let s:Guard = a:V.import('Vim.Guard')
endfunction

function! s:_vital_depends() abort
  return ['Vim.Guard']
endfunction

function! s:_throw(msg) abort
  throw 'vital: ProgressBar: ' . a:msg
endfunction

function! s:new(maxvalue, ...) abort
  let options = extend({
        \ 'barwidth': 80,
        \ 'nullchar': '.',
        \ 'fillchar': '|',
        \ 'format': '|%(fill)s%(null)s| %(percent)s%',
        \ 'method': 'echo'
        \}, get(a:000, 0, {}))
  " Validate
  if index(['echo', 'statusline'], options.method) == -1
    call s:_throw(printf('"%s" is not a valid method', options.method))
  elseif options.method ==# 'statusline' && has('vim_starting')
    call s:_throw('"statusline" method could not be used in "vim_starting"')
  endif
  " Calculate alpha value
  let maxvalue = str2nr(a:maxvalue)
  let barwidth = str2nr(options.barwidth)
  let alpha = barwidth / str2float(maxvalue)
  let instance = extend(deepcopy(s:instance), {
        \ 'maxvalue': maxvalue,
        \ 'barwidth': barwidth,
        \ 'alpha': alpha,
        \ 'nullchar': options.nullchar,
        \ 'fillchar': options.fillchar,
        \ 'nullbar': repeat(options.nullchar, barwidth),
        \ 'fillbar': repeat(options.fillchar, barwidth),
        \ 'format': options.format,
        \ 'method': options.method,
        \ 'current': 0,
        \})
  " Lock readonly options; options which require to be initialized or involved
  " in .new() method. Users require to create a new progressbar instance if
  " they want to modify such options
  lockvar instance.maxvalue
  lockvar instance.barwidth
  lockvar instance.alpha
  lockvar instance.nullchar
  lockvar instance.fillchar
  lockvar instance.nullbar
  lockvar instance.fillbar
  lockvar instance.method
  if instance.method ==# 'statusline'
    let instance._guard = s:Guard.store([
          \ '&l:statusline',
          \])
  elseif instance.method ==# 'echo'
    let instance._guard = s:Guard.store([
          \ '&more',
          \ '&showcmd',
          \ '&ruler',
          \])
    set nomore
    set noshowcmd
    set noruler
  endif
  call s:_redraw(instance)
  return instance
endfunction

function! s:_construct(progressbar, value) abort
  let percent = float2nr(a:value / str2float(a:progressbar.maxvalue) * 100)
  let fillwidth = float2nr(ceil(a:value * a:progressbar.alpha))
  let nullwidth = a:progressbar.barwidth - fillwidth
  let fillstr = fillwidth == 0 ? '' : a:progressbar.fillbar[ : fillwidth-1]
  let nullstr = nullwidth == 0 ? '' : a:progressbar.nullbar[ : nullwidth-1]
  let indicator = a:progressbar.format
  let indicator = substitute(indicator, '%(fill)s', fillstr, '')
  let indicator = substitute(indicator, '%(null)s', nullstr, '')
  let indicator = substitute(indicator, '%(percent)s', percent, '')
  return indicator
endfunction

function! s:_redraw(progressbar) abort
  let indicator = s:_construct(a:progressbar, a:progressbar.current)
  if indicator ==# get(a:progressbar, '_previous', '')
    " skip
    return
  endif
  if a:progressbar.method ==# 'statusline'
    let &l:statusline = indicator
    redrawstatus
  elseif a:progressbar.method ==# 'echo'
    redraw | echo indicator
  endif
  let a:progressbar._previous = indicator
endfunction

let s:instance = {}

function! s:instance.update(...) abort
  let value = get(a:000, 0, self.current + 1)
  let self.current = value > self.maxvalue ? self.maxvalue : value
  call s:_redraw(self)
endfunction

function! s:instance.exit() abort
  let self.current = self.maxvalue
  call s:_redraw(self)
  if has_key(self, '_guard')
    call self._guard.restore()
  endif
endfunction
