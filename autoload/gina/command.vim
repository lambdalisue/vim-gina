let s:Argument = vital#gina#import('Argument')
let s:Console = vital#gina#import('Vim.Console')
let s:Emitter = vital#gina#import('Emitter')
let s:Exception = vital#gina#import('Vim.Exception')
let s:command_alias = {}


function! gina#command#alias(scheme, qargs) abort
  let s:command_alias[a:scheme] = a:qargs
endfunction

function! gina#command#command(bang, range, qargs, qmods) abort
  if a:bang ==# '!'
    let git = gina#core#get()
    let args = s:Argument.new(s:normalize_qargs(a:qargs))
    let result = gina#util#process#call(git, args.raw)
    call gina#util#process#inform(result)
    call s:Emitter.emit('gina:modified')
  else
    let qargs = s:normalize_qargs(a:qargs)
    let scheme = substitute(
          \ matchstr(qargs, '^\S\+'),
          \ '-', '_', 'g'
          \)
    if !empty(scheme)
      try
        return s:Exception.call(
              \ printf('gina#command#%s#command', scheme),
              \ [a:range, qargs, a:qmods]
              \)
      catch /^Vim\%((\a\+)\)\=:E117: [^:]\+: gina#command#[^#]\+#command/
        call s:Console.debug(v:exception)
        call s:Console.debug(v:throwpoint)
      endtry
    endif
    " Fallback to a raw git command
    call gina#command#command('!', a:range, a:qargs, a:qmods)
  endif
endfunction

function! gina#command#complete(arglead, cmdline, cursorpos) abort
  if a:cmdline =~# printf('^Gina %s$', a:arglead)
    return filter(s:get_installed_commands(), 'v:val =~# ''^'' . a:arglead')
  endif
  let cmdline = matchstr(a:cmdline, '^Gina \zs.*')
  let scheme = matchstr(cmdline, '^\S\+')
  if !empty(scheme)
    try
      return s:Exception.call(
            \ printf('gina#command#%s#complete', scheme),
            \ [a:arglead, cmdline, a:cursorpos]
            \)
    catch /^Vim\%((\a\+)\)\=:E117: [^:]\+: gina#command#[^#]\+#complete/
      call s:Console.debug(v:exception)
      call s:Console.debug(v:throwpoint)
    endtry
  endif
  return gina#complete#filename#any(a:arglead, cmdline, a:cursorpos)
endfunction

function! gina#command#autocmd(name) abort
  let params = gina#util#path#params(expand('<afile>'))
  let scheme = substitute(
        \ params.scheme,
        \ '-', '_', 'g'
        \)
  return s:Exception.call(
        \ printf('gina#command#%s#%s', scheme, a:name),
        \ []
        \)
endfunction


" Private --------------------------------------------------------------------
function! s:normalize_qargs(qargs) abort
  let scheme = matchstr(a:qargs, '^\w\+')
  let option = matchstr(a:qargs, '^\w\+ \zs.*')
  let alias = get(s:command_alias, scheme, scheme)
  if a:qargs =~# '^' . alias
    return a:qargs
  endif
  return substitute(a:qargs, '^\w\+', alias, '')
endfunction

function! s:get_installed_commands() abort
  let commands = []
  for path in split(&runtimepath, ',')
    let names = map(
          \ glob(path . '/autoload/gina/command/*.vim', 0, 1),
          \ 'matchstr(v:val, ''[^/]\+\ze\.vim$'')',
          \)
    call map(names, 'substitute(v:val, ''_'', ''-'', ''g'')')
    call extend(commands, names)
  endfor
  return sort(commands)
endfunction
