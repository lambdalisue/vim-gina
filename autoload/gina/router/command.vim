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
    let args = gina#command#parse(a:args)
    let args.params = {}
    let args.params.async = args.pop('--async')
    if args.params.async
      call gina#process#open(git, args.raw, {
            \ 'on_stdout': function('s:on_stdout'),
            \ 'on_stderr': function('s:on_stderr'),
            \ 'on_exit': function('s:on_exit'),
            \})
    else
      let result = gina#process#call(git, args.raw)
      call gina#process#inform(result)
      call s:Emitter.emit('gina:modified')
    endif
  else
    let command = gina#router#command#get(matchstr(a:args, '^\S\+'))
    if command is# v:null
      call gina#router#command#call('!', a:range, a:args, a:mods)
    else
      call s:Exception.call(
            \ command.command,
            \ [a:range, a:args, a:mods],
            \ command
            \)
    endif
  endif
endfunction


" Private --------------------------------------------------------------------
function! s:on_stdout(job, msg, event) abort dict
  for line in a:msg
    echomsg line
  endfor
endfunction

function! s:on_stderr(job, msg, event) abort dict
  echohl ErrorMsg
  for line in a:msg
    echomsg line
  endfor
  echohl None
endfunction

function! s:on_exit(job, msg, event) abort dict
  call s:Emitter.emit('gina:modified')
endfunction
