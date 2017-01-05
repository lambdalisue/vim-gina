let s:t_string = type('')

function! s:_vital_loaded(V) abort
  let s:Buffer = a:V.import('Vim.Buffer')
  let s:BufferManager = a:V.import('Vim.BufferManager')
endfunction

function! s:_vital_depends() abort
  return ['Vim.Buffer', 'Vim.BufferManager']
endfunction


" Public ---------------------------------------------------------------------
function! s:open(buffer, ...) abort
  let config = extend({
        \ 'opener': 'edit',
        \ 'group': '',
        \ 'range': 'tabpage',
        \ 'force': 1,
        \}, get(a:000, 0, {})
        \)
  " validate and normalize {opener}
  if type(config.opener) != s:t_string
    throw 'vital: Vim.Buffer.Opener: {opener} must be String'
  endif
  let opener = empty(config.opener) ? 'edit' : config.opener
  while opener[0] ==# '='
    sandbox let opener = eval(opener[1:])
  endwhile

  let preview = s:is_preview_opener(opener)
  let bufloaded = bufloaded(a:buffer)
  let bufexists = bufexists(a:buffer)

  if empty(config.group) || preview
    call s:Buffer.open(a:buffer, opener)
  else
    let manager = s:_get_buffer_manager(config.group)
    call manager.open(a:buffer, {
          \ 'opener': opener,
          \ 'range': config.range,
          \})
  endif

  let context = {
        \ 'preview': preview,
        \ 'bufloaded': bufloaded,
        \ 'bufexists': bufexists,
        \}
  if config.force && preview
    let context.focusto = bufnr('%')
    silent keepjumps keepalt wincmd P
  endif
  let context.bufnr = bufnr('%')
  let context.bufname = bufname('%')
  return extend(context, s:context)
endfunction

function! s:is_preview_opener(opener) abort
  if a:opener =~# '\<ptag\?!\?\>'
    return 1
  elseif a:opener =~# '\<ped\%[it]!\?\>'
    return 1
  elseif a:opener =~# '\<ps\%[earch]!\?\>'
    return 1
  endif
  return 0
endfunction


" Context --------------------------------------------------------------------
let s:context = {}
function! s:context.end() abort
  let focusto = get(self, 'focusto', -1)
  if focusto == -1 || focusto == bufnr('%')
    return
  endif
  silent unlet self.focusto
  silent execute printf('keepjumps keepalt %dwincmd w', bufwinnr(focusto))
endfunction


" Private --------------------------------------------------------------------
function! s:_get_buffer_manager(group) abort
  let group = substitute(a:group, '-', '_', 'g')
  if exists('s:_bm_' . group)
    return s:_bm_{group}
  endif
  let s:_bm_{group} = s:BufferManager.new()
  return s:_bm_{group}
endfunction
