let s:prefix = 'vital_vim_buffer_doom'
let s:cascades = {}

function! s:new(name) abort
  let doom = extend(deepcopy(s:doom), {
        \ 'name': substitute(a:name, '\W', '_', 'g'),
        \})
  return doom
endfunction


let s:doom = {
      \ 'companies': [],
      \ 'properties': {},
      \}

function! s:doom.involve(expr, ...) abort
  let property = extend({
        \ 'keep': 0,
        \}, get(a:000, 0, {})
        \)
  let bufnr = bufnr(a:expr)
  let winid = bufwinid(a:expr)
  let self.companies += [bufnr]
  let self.properties[string(bufnr)] = property
  call setbufvar(bufnr, printf('_%s_%s', s:prefix, self.name), self)

  execute printf('augroup %s_%s', s:prefix, self.name)
  execute printf('autocmd! * <buffer=%d>', bufnr)
  execute printf('autocmd WinLeave <buffer=%d> call s:_on_WinLeave(''%s'')', bufnr, self.name)
  execute printf('autocmd WinEnter * call s:_on_WinEnter(''%s'')', self.name)
  execute 'augroup END'
endfunction

function! s:doom.annihilate() abort
  for bufnr in self.companies
    execute printf('augroup %s_%s', s:prefix, self.name)
    execute printf('autocmd! * <buffer=%d>', bufnr)
    execute 'augroup END'

    let winnr = bufwinnr(bufnr)
    let property = self.properties[string(bufnr)]
    if property.keep || !bufexists(bufnr) || winnr == -1 || getbufvar(bufnr, '&modified')
      continue
    endif
    execute printf('%dclose', winnr)
  endfor
endfunction

function! s:_on_WinLeave(name) abort
  let vname = printf('_%s_%s', s:prefix, a:name)
  if exists('b:' . vname)
    let s:cascades[a:name] = {
          \ 'nwin': winnr('$'),
          \ 'doom': get(b:, vname),
          \}
  endif
endfunction

function! s:_on_WinEnter(name) abort
  if has_key(s:cascades, a:name)
    if winnr('$') < s:cascades[a:name].nwin
      call s:cascades[a:name].doom.annihilate()
    endif
    unlet s:cascades[a:name]
  endif
endfunction
