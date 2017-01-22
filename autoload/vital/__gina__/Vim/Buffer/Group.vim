function! s:_vital_created(module) abort
  let s:groups = {}
endfunction


function! s:new() abort
  let hash = sha256(reltimestr(reltime()))
  let s:groups[hash] = copy(s:group)
  let s:groups[hash].__hash = hash
  let s:groups[hash].__tabnr = tabpagenr()
  let s:groups[hash].__members = []
  return s:groups[hash]
endfunction


let s:group = {}

function! s:group.add(...) abort
  let options = extend({
        \ 'keep': 0,
        \}, get(a:000, 0, {})
        \)
  let bufnr = bufnr('%')
  let winid = bufwinid('%')
  let tabnr = tabpagenr()
  if tabnr != self.__tabnr
    throw printf(
          \ 'vital: Vim.Buffer.Group: %s',
          \ 'A buffer on a different tabpage cannot be added.'
          \)
  endif
  call add(self.__members, {
        \ 'bufnr': bufnr,
        \ 'winid': winid,
        \ 'options': options,
        \})
  execute printf('augroup vital_vim_buffer_group_%s', self.__hash)
  execute printf('autocmd! * <buffer=%d>', bufnr)
  execute printf('autocmd WinLeave <buffer=%d> call s:_on_WinLeave(''%s'')', bufnr, self.__hash)
  execute 'augroup END'
endfunction

function! s:group.close() abort
  for member in self.__members
    if member.options.keep
      continue
    endif
    let winnr = win_id2win(member.winid)
    if winnr == 0 || getbufvar(member.bufnr, '&modified') || bufwinid(member.bufnr) != member.winid
      continue
    endif
    silent execute printf('%dclose', winnr)
  endfor
endfunction


function! s:_on_WinLeave(hash) abort
  execute 'augroup vital_vim_buffer_group_temporal_' . a:hash
  execute 'autocmd! *'
  execute printf(
        \ 'autocmd WinEnter * call s:_on_WinEnter(''%s'', %d)',
        \ a:hash, winnr('$'),
        \)
  execute 'augroup END'
endfunction

function! s:_on_WinEnter(hash, nwin) abort
  execute 'augroup vital_vim_buffer_group_temporal_' . a:hash
  execute 'autocmd! *'
  execute 'augroup END'
  if winnr('$') < a:nwin
    call s:groups[a:hash].close()
  endif
endfunction
