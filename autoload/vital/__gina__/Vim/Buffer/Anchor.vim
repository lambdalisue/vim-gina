function! s:_vital_loaded(V) abort
  let s:Dict = a:V.import('Data.Dict')
  let s:config = {
        \ 'buflisted_required': 1,
        \ 'unsuitable_buftype_pattern': '^\%(nofile\|quickfix\)$',
        \ 'unsuitable_bufname_pattern': '',
        \ 'unsuitable_filetype_pattern': '',
        \}
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Data.Dict',
        \ 'Vim.Compat',
        \]
endfunction

function! s:get_config() abort
  return copy(s:config)
endfunction

function! s:set_config(config) abort
  let s:config = extend(s:config, s:Dict.pick(a:config, [
        \ 'buflisted_required',
        \ 'unsuitable_buftype_pattern',
        \ 'unsuitable_bufname_pattern',
        \ 'unsuitable_filetype_pattern',
        \]))
endfunction

function! s:is_available(opener) abort
  if a:opener =~# '\<p\%[tag]!\?\>'
    return 0
  elseif a:opener =~# '\<ped\%[it]!\?\>'
    return 0
  elseif a:opener =~# '\<ps\%[earch]!\?\>'
    return 0
  elseif a:opener =~# '\<\%(tabe\%[dit]\|tabnew\)\>'
    return 0
  elseif a:opener =~# '\<tabf\%[ind]\>'
    return 0
  endif
  return 1
endfunction

function! s:is_suitable(winnum) abort
  let bufnum  = winbufnr(a:winnum)
  if empty(bufname(bufnum))
    return 1
  elseif s:config.buflisted_required && !buflisted(bufnum)
    return 0
  elseif !empty(s:config.unsuitable_bufname_pattern)
        \ && bufname(bufnum) =~# s:config.unsuitable_bufname_pattern
    return 0
  elseif !empty(s:config.unsuitable_buftype_pattern)
        \ && getbufvar(bufnum, '&buftype') =~# s:config.unsuitable_buftype_pattern
    return 0
  elseif !empty(s:config.unsuitable_filetype_pattern)
        \ && getbufvar(bufnum, '&filetype') =~# s:config.unsuitable_filetype_pattern
    return 0
  endif
  return 1
endfunction

function! s:find_suitable(winnum, ...) abort
  let winnum = max([1, a:winnum])
  if winnr('$') == 1
    return 1
  endif
  let is_reverse = get(a:000, 0, 0)
  let rangeset = is_reverse
        \ ? [reverse(range(1, winnum)), reverse(range(winnum + 1, winnr('$')))]
        \ : [range(winnum, winnr('$')), range(1, winnum - 1)]
  " find a suitable window in rightbelow from a previous window
  for winnum in rangeset[0]
    if s:is_suitable(winnum)
      return winnum
    endif
  endfor
  " find a suitable window in leftabove to before a previous window
  for winnum in rangeset[1]
    if s:is_suitable(winnum)
      return winnum
    endif
  endfor
  " no suitable window is found.
  return 0
endfunction

function! s:focus(...) abort
  if s:is_suitable(winnr())
    return
  endif
  " find suitable window from the previous window
  let previous_winnum = winnr('#')
  let suitable_winnum = s:find_suitable(previous_winnum, get(a:000, 0, 0))
  let suitable_winnum = suitable_winnum == 0
        \ ? previous_winnum
        \ : suitable_winnum
  silent execute printf('keepjumps %dwincmd w', suitable_winnum)
endfunction

function! s:focus_if_available(opener, ...) abort
  if s:is_available(a:opener)
    call call('s:focus', a:000)
  endif
endfunction

function! s:attach() abort
  augroup vital_vim_buffer_anchor_internal
    autocmd! *
    autocmd WinLeave <buffer> call s:_on_WinLeave()
    autocmd WinEnter * call s:_on_WinEnter()
  augroup END
endfunction

function! s:_on_WinLeave() abort
  let s:_vital_vim_buffer_anchor_winleave = winnr('$')
endfunction

function! s:_on_WinEnter() abort
  if exists('s:_vital_vim_buffer_anchor_winleave')
    let nwin = s:_vital_vim_buffer_anchor_winleave
    if winnr('$') < nwin
      call s:focus(1)
    endif
    unlet s:_vital_vim_buffer_anchor_winleave
  endif
endfunction
