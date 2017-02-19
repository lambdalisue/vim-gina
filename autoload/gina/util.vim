let s:Dict = vital#gina#import('Data.Dict')
let s:File = vital#gina#import('System.File')
let s:String = vital#gina#import('Data.String')
let s:DIRECTION_PATTERN = printf('\<\%%(%s\)\>', join([
      \ 'lefta\%[bove]',
      \ 'abo\%[veleft]',
      \ 'rightb\%[elow]',
      \ 'bel\%[owright]',
      \ 'to\%[pleft]',
      \ 'bo\%[tright]',
      \], '\|')
      \)
let s:t_list = type([])


function! gina#util#contain_direction(mods) abort
  return a:mods =~# s:DIRECTION_PATTERN
endfunction

function! gina#util#yank(value) abort
  call setreg(v:register, a:value)
endfunction

function! gina#util#open(uri) abort
  call s:File.open(a:uri)
endfunction

function! gina#util#filter(arglead, candidates, ...) abort
  let hidden_pattern = get(a:000, 0, '')
  let pattern = '^' . s:String.escape_pattern(a:arglead)
  let candidates = copy(a:candidates)
  if empty(a:arglead) && !empty(hidden_pattern)
    call filter(candidates, 'v:val !~# hidden_pattern')
  endif
  call filter(candidates, 'v:val =~# pattern')
  return candidates
endfunction

function! gina#util#shellescape(value, ...) abort
  if empty(a:value)
    return ''
  endif
  let value = type(a:value) == s:t_list
        \ ? join(map(copy(a:value), 'shellescape(v:val)'))
        \ : shellescape(a:value)
  let prefix = get(a:000, 0, '')
  return prefix . value
endfunction

function! gina#util#fnameescape(value, ...) abort
  if empty(a:value)
    return ''
  endif
  let value = type(a:value) == s:t_list
        \ ? join(map(copy(a:value), 'fnameescape(v:val)'))
        \ : fnameescape(a:value)
  let prefix = get(a:000, 0, '')
  return prefix . value
endfunction

function! gina#util#doautocmd(name, ...) abort
  let pattern = get(a:000, 0, '')
  let expr = '#' . a:name
  let eis = split(&eventignore, ',')
  if index(eis, a:name) != -1 || index(eis, 'all') != -1 || !exists(expr)
    " the specified event is ignored or does not exists
    return
  endif
  let is_pseudo_required = empty(pattern) && !exists('#' . a:name . '#*')
  if is_pseudo_required
    " NOTE:
    " autocmd XXXXX <pattern> exists but not sure if the current buffer name
    " match with the <pattern> so register an empty autocmd to prevent
    " 'No matching autocommands' warning
    augroup gina_internal_util_doautocmd
      autocmd! *
      execute printf('autocmd %s * :', a:name)
    augroup END
  endif
  let nomodeline = has('patch-7.4.438') && a:name ==# 'User'
        \ ? '<nomodeline> '
        \ : ''
  try
    execute printf('doautocmd %s %s %s', nomodeline, a:name, pattern)
  finally
    if is_pseudo_required
      augroup gina_internal_util_doautocmd
        autocmd! *
      augroup END
    endif
  endtry
endfunction

function! gina#util#syncbind() abort
  " NOTE:
  " 'syncbind' does not work just after a buffer has opened
  " so use timer to delay the command.
  call timer_start(100, function('s:syncbind'))
endfunction

function! gina#util#diffthis() abort
  diffthis
  augroup gina_internal_util_diffthis
    autocmd! * <buffer>
    autocmd BufHidden <buffer> call s:diffoff()
    autocmd BufUnload <buffer> call s:diffoff()
    autocmd BufDelete <buffer> call s:diffoff()
    autocmd BufWipeout <buffer> call s:diffoff()
  augroup END
endfunction

function! gina#util#diffupdate() abort
  " NOTE:
  " 'diffupdate' does not work just after a buffer has opened
  " so use timer to delay the command.
  call timer_start(100, function('s:diffupdate'))
endfunction

function! s:syncbind(...) abort
  syncbind
endfunction

function! gina#util#inherit(super, ...) abort
  let prototype = a:0 ? a:1 : {}
  let instance = extend(copy(a:super), prototype)
  let instance.super = function('s:call_super')
  let instance.__super = s:Dict.omit(a:super, ['super', '__super'])
  return instance
endfunction


" Private --------------------------------------------------------------------
function! s:diffoff() abort
  augroup gina_internal_util_diffthis
    autocmd! * <buffer>
  augroup END
  diffoff
  diffupdate
endfunction

function! s:diffupdate(...) abort
  diffupdate
  syncbind
endfunction

function! s:call_super(cls, method, ...) abort dict
  return call(a:cls.__super[a:method], a:000, self)
endfunction
