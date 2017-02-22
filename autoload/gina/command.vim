let s:Argument = vital#gina#import('Argument')


function! gina#command#call(bang, range, rargs, mods) abort
  if a:bang ==# '!'
    return gina#command#call('', a:range, '_raw ' . a:rargs, a:mods)
  endif
  let args = s:build_args(a:rargs)
  try
    call gina#core#exception#call(
          \ printf('gina#command#%s#call', args.params.scheme),
          \ [a:range, args, a:mods],
          \)
    return
  catch /^Vim\%((\a\+)\)\=:E117: [^:]\+: gina#command#[^#]\+#call/
    call gina#core#console#debug(v:exception)
    call gina#core#console#debug(v:throwpoint)
  endtry
  return gina#command#call('', a:range, '_raw ' . a:rargs, a:mods)
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

function! gina#command#scheme(sfile) abort
  let name = fnamemodify(a:sfile, ':t')
  let name = matchstr(name, '.*\ze\.vim')
  let scheme = substitute(name, '_', '-', 'g')
  return scheme
endfunction


" Obsolete -------------------------------------------------------------------
function! gina#command#custom(scheme, query, ...) abort
  call gina#core#console#warn(
        \ 'gina#command#custom is obsolete. Use gina#custom#command#option'
        \)
  call gina#custom#command#option(a:scheme, a:query, get(a:000, 0, 1))
endfunction


" Private
function! s:build_args(rargs) abort
  let args = s:Argument.new(a:rargs)
  let preference = gina#custom#command#preference(args.get(0))
  " Assign default options
  for [query, value, remover] in preference.options
    if !empty(remover) && args.has(remover)
      call args.pop(remover)
      call args.pop(query)
    elseif !args.has(query)
      call args.set(query, value)
    endif
  endfor
  " Assign alias
  if preference.raw
    call args.set(0, ['_raw', preference.origin])
  else
    call args.set(0, preference.origin)
  endif
  " Expand residuals to allow '%'
  let pathlist = args.residual()
  if !empty(pathlist)
    call args.residual(map(pathlist, 'gina#core#path#expand(v:val)'))
  endif
  " Assig global params
  let args.params = {}
  let args.params.scheme = args.get(0, '')
  let cmd = args.pop('^+')
  let cmdarg = []
  while !empty(cmd)
    call add(cmdarg, cmd)
    let cmd = args.pop('^+')
  endwhile
  let args.params.cmdarg = empty(cmdarg) ? '' : (join(cmdarg) . ' ')
  return args
endfunction
