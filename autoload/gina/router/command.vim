let s:Argument = vital#gina#import('Argument')
let s:Emitter = vital#gina#import('Emitter')
let s:Exception = vital#gina#import('Vim.Exception')


function! gina#router#command#list() abort
  if exists('s:commands') && !g:gina#develop
    return s:commands
  endif
  let s:commands = gina#router#load_modules('command')
  return s:commands
endfunction

function! gina#router#command#get(scheme) abort
  let scheme = substitute(a:scheme, '-', '_', 'g')
  let commands = gina#router#command#list()
  return get(commands, scheme, v:null)
endfunction

function! gina#router#command#call(bang, range, args, mods) abort
  if a:bang ==# '!'
    let git = gina#core#get()
    let args = s:Argument.new(a:args)
    let result = gina#process#call(git, args.raw)
    call gina#process#inform(result)
    call s:Emitter.emit('gina:modified')
    return result
  endif
  let command = gina#router#command#get(matchstr(a:args, '^\S\+'))
  if command is# v:null
    return gina#router#command#call('!', a:range, a:args, a:mods)
  endif
  return s:Exception.call(
        \ command.command,
        \ [a:range, a:args, a:mods],
        \ command
        \)
endfunction
