let s:Argument = vital#gina#import('Argument')
let s:Config = vital#gina#import('Config')

let s:t_number = type(0)


function! gina#command#call(bang, range, args, mods) abort
  if a:bang ==# '!'
    return gina#command#call('', a:range, '_raw ' . a:args, a:mods)
  endif
  let scheme = matchstr(a:args, '^\S\+')
  let scheme = substitute(scheme, '!$', '', '')
  let scheme = substitute(scheme, '\W', '_', 'g')
  try
    call gina#core#exception#call(
          \ printf('gina#command#%s#call', scheme),
          \ [a:range, a:args, a:mods],
          \)
    return
  catch /^Vim\%((\a\+)\)\=:E117: [^:]\+: gina#command#[^#]\+#call/
    call gina#core#console#debug(v:exception)
    call gina#core#console#debug(v:throwpoint)
  endtry
  return gina#command#call('', a:range, '_raw ' . a:args, a:mods)
endfunction

function! gina#command#complete(arglead, cmdline, cursorpos) abort
  if a:cmdline =~# '^Gina!'
    return gina#command#complete(
          \ a:arglead,
          \ substitute(a:cmdline, '^Gina!', 'Gina _raw', ''),
          \ a:cursorpos,
          \)
  elseif a:cmdline =~# printf('^Gina\s\+%s$', a:arglead)
    return gina#complete#common#command(a:arglead, a:cmdline, a:cursorpos)
  endif
  let cmdline = matchstr(a:cmdline, '^Gina\s\+\zs.*')
  let scheme = matchstr(cmdline, '^\S\+')
  let scheme = substitute(scheme, '!$', '', '')
  let scheme = substitute(scheme, '\W', '_', 'g')
  try
    return gina#core#exception#call(
          \ printf('gina#command#%s#complete', scheme),
          \ [a:arglead, cmdline, a:cursorpos],
          \)
  catch /^Vim\%((\a\+)\)\=:E117: [^:]\+: gina#command#[^#]\+#complete/
    call gina#core#console#debug(v:exception)
    call gina#core#console#debug(v:throwpoint)
  endtry
  return gina#command#complete(
        \ a:arglead,
        \ substitute(a:cmdline, '^Gina', 'Gina _raw', ''),
        \ a:cursorpos,
        \)
endfunction

function! gina#command#parse_args(args) abort
  let args = s:Argument.new(a:args)
  let custom = s:get_custom(args.get(0))
  for [query, value, remover] in custom
    if !empty(remover) && args.has(remover)
      call args.pop(remover)
      call args.pop(query)
    elseif !args.has(query)
      call args.set(query, value)
    endif
  endfor
  " Expand residuals to allow '%'
  let pathlist = args.residual()
  if !empty(pathlist)
    call args.residual(map(pathlist, 'gina#core#path#expand(v:val)'))
  endif
  " Assig global params
  let args.params = {}
  let args.params.scheme = args.get(0, '')
  let args.params.async = args.pop('--async')
  let args.params.cmdarg = join([
        \ args.pop('^++enc'),
        \ args.pop('^++ff'),
        \])
  return args
endfunction

function! gina#command#custom(scheme, query, ...) abort
  if a:query !~# '^--\?\S\+\%(|--\?\S\+\)*$'
    throw 'gina: Invalid query has specified. See :h gina#command#custom'
  endif
  let value = get(a:000, 0, 1)
  let remover = type(value) == s:t_number ? s:build_remover(a:query) : ''
  let custom = s:get_custom(a:scheme)
  call add(custom, [a:query, value, remover])
endfunction


" Private --------------------------------------------------------------------
function! s:get_custom(scheme) abort
  let scheme = substitute(a:scheme, '\W', '_', 'g')
  if !exists('s:custom_' . scheme)
    let s:custom_{scheme} = []
  endif
  return s:custom_{scheme}
endfunction

function! s:build_remover(query) abort
  let terms = split(a:query, '|')
  let names = map(copy(terms), 'matchstr(v:val, ''^--\?\zs\S\+'')')
  let remover = map(
        \ range(len(terms)),
        \ '(terms[v:val] =~# ''^--'' ? ''--no-'' : ''-!'') . names[v:val]'
        \)
  return join(remover, '|')
endfunction
