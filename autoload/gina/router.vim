let s:Argument = vital#gina#import('Argument')
let s:Cache = vital#gina#import('System.Cache.Memory')
let s:Console = vital#gina#import('Vim.Console')
let s:Emitter = vital#gina#import('Emitter')
let s:Exception = vital#gina#import('Vim.Exception')
let s:Path = vital#gina#import('System.Filepath')


function! gina#router#load_modules(category) abort
  let cache = s:get_cache()
  if cache.has(a:category)
    return cache.get(a:category)
  endif
  call cache.set(a:category, s:load_modules(a:category))
  return cache.get(a:category)
endfunction

function! gina#router#clear_modules(category) abort
  let cache = s:get_cache()
  call cache.remove(a:category)
endfunction

function! gina#router#command(bang, range, qargs, qmods) abort
  if a:bang ==# '!'
    let git = gina#core#get()
    let args = s:Argument.new(a:qargs)
    return gina#command#call(git, args)
  endif
  let command = s:get_command(matchstr(a:qargs, '^\S\+'))
  if command is# v:null
    return gina#router#command('!', a:range, a:qargs, a:qmods)
  endif
  return s:Exception.call(
        \ command.command,
        \ [a:range, a:qargs, a:qmods],
        \ command
        \)
endfunction

function! gina#router#complete(arglead, cmdline, cursorpos) abort
  if a:cmdline =~# printf('^Gina %s$', a:arglead)
    let commands = s:load_commands()
    return filter(keys(commands), 'v:val =~# ''^'' . a:arglead')
  endif
  let cmdline = matchstr(a:cmdline, '^Gina \zs.*')
  let command = s:get_command(matchstr(cmdline, '^\S\+'))
  if command is# v:null || !has_key(command, 'complete')
    return gina#complete#filename#any(a:arglead, cmdline, a:cursorpos)
  endif
  return s:Exception.call(
        \ command.complete,
        \ [a:arglead, cmdline, a:cursorpos],
        \ command
        \)
endfunction

function! gina#router#autocmd(name) abort
  let params = gina#util#path#params(expand('<afile>'))
  let command = s:get_command(params.scheme)
  if command is# v:null
    return s:Console.error(printf(
          \ 'No command module "%s" is defined.'),
          \ params.scheme,
          \)
  elseif !has_key(command, a:name)
    return s:Console.error(printf(
          \ 'A command module "%s" does not define an autocmd "%s".'),
          \ params.scheme, a:name,
          \)
  endif
  return s:Exception.call(command[a:name], [], command)
endfunction


" Private --------------------------------------------------------------------
function! s:get_cache() abort
  if exists('s:cache')
    return s:cache
  endif
  let s:cache = s:Cache.new()
  return s:cache
endfunction

function! s:get_command(scheme) abort
  let scheme = substitute(a:scheme, '-', '_', 'g')
  let commands = s:load_commands()
  return get(commands, scheme, v:null)
endfunction

function! s:load_commands() abort
  if exists('s:commands') && !g:gina#develop
    return s:commands
  endif
  let s:commands = gina#router#load_modules('command')
  return s:commands
endfunction

function! s:load_modules(category) abort
  let suffix = s:Path.realpath(printf('autoload/gina/%s/*.vim', a:category))
  let modules = {}
  for runtimepath in split(&runtimepath, ',')
    let module_names = map(
          \ glob(s:Path.join(runtimepath, suffix), 0, 1),
          \ 'matchstr(v:val, ''[^/]\+\ze\.vim$'')',
          \)
    for module_name in module_names
      let modules[module_name] = s:load_module(a:category, module_name)
    endfor
  endfor
  return filter(modules, 'v:val isnot# v:null')
endfunction

function! s:load_module(category, name) abort
  try
    return call(printf('gina#%s#%s#define', a:category, a:name), [])
  catch /^Vim\%((\a\+)\)\=:E117: [^:]\+: gina#.*#define/
    call s:Console.debug(v:exception)
    call s:Console.debug(v:throwpoint)
  endtry
  return v:null
endfunction
