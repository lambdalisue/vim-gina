function! s:_vital_created(module) abort
  let s:name = sha256(expand('<sfile>'))
  let s:prefix = 'vital_internal_vim_buffer_observer'
  let s:registry = {}
  let s:t_string = type('')
endfunction


function! s:attach(...) abort
  let Function_or_command = get(a:000, 0, 'edit')
  let bufnum = string(bufnr('%'))
  let s:registry[bufnum] = {
        \ 'callback': Function_or_command,
        \ 'args': a:000[1 : ],
        \}
  return s:registry[bufnum]
endfunction

function! s:update() abort
  let winview_saved = winsaveview()
  let winnum_saved = winnr()
  try
    for bufnum in keys(s:registry)
      let winnum = bufwinnr(str2nr(bufnum))
      if winnum > 0
        silent execute printf('noautocmd keepalt keepjumps %dwincmd w', winnum)
        silent call s:_update()
        continue
      elseif bufexists(str2nr(bufnum))
        execute printf('augroup %s_%s', s:prefix, s:name)
        execute printf('autocmd! * <buffer=%s>', bufnum)
        execute printf(
              \ 'autocmd WinEnter <buffer=%s> nested call s:_on_WinEnter()',
              \ bufnum,
              \)
        execute printf(
              \ 'autocmd BufWinEnter <buffer=%s> nested call s:_on_WinEnter()',
              \ bufnum,
              \)
        execute 'augroup END'
        continue
      else
        silent unlet s:registry[bufnum]
      endif
    endfor
  finally
    silent execute printf('noautocmd keepalt keepjumps %dwincmd w', winnum_saved)
    silent keepjumps call winrestview(winview_saved)
  endtry
endfunction

function! s:clear() abort
  let s:registry = {}
endfunction

function! s:_update() abort
  let bufnum = string(bufnr('%'))
  let info = get(s:registry, bufnum, {})
  if empty(info)
    return
  elseif !&autoread
    return
  endif
  if type(info.callback) == s:t_string
    execute info.callback
  else
    call call(info.callback, info.args, info)
  endif
endfunction

function! s:_on_WinEnter() abort
  if !exists(printf('#%s_%s', s:prefix, s:name))
    return
  endif
  execute printf('augroup %s_%s', s:prefix, s:name)
  execute 'autocmd! * <buffer>'
  execute 'augroup END'
  call s:_update()
endfunction
