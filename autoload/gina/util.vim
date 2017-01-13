let s:File = vital#gina#import('System.File')
let s:String = vital#gina#import('Data.String')


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
  let prefix = get(a:000, 0, '')
  return prefix . shellescape(a:value)
endfunction

function! gina#util#fnameescape(value, ...) abort
  if empty(a:value)
    return ''
  endif
  let prefix = get(a:000, 0, '')
  return prefix . fnameescape(a:value)
endfunction

function! gina#util#doautocmd(name, ...) abort
  let pattern = get(a:000, 0, '')
  let expr = empty(pattern)
        \ ? '#' . a:name
        \ : '#' . a:name . '#' . pattern
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

function! gina#util#map(mode, lhs, rhs) abort
  for mode in split(a:mode, '\zs')
    if !hasmapto(a:rhs, mode)
      execute printf('%smap <buffer> %s %s', mode, a:lhs, a:rhs)
    endif
  endfor
endfunction

function! gina#util#nmap(lhs, rhs) abort
  call gina#util#map('n', a:lhs, a:rhs)
endfunction

function! gina#util#imap(lhs, rhs) abort
  call gina#util#map('i', a:lhs, a:rhs)
endfunction

function! gina#util#vmap(lhs, rhs) abort
  call gina#util#map('v', a:lhs, a:rhs)
endfunction

function! s:syncbind(...) abort
  syncbind
endfunction

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
