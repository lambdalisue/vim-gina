let s:Path = vital#gina#import('System.Filepath')

let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#edit#call(range, args, mods) abort
  call gina#process#register(s:SCHEME, 1)
  try
    call s:call(a:range, a:args, a:mods)
  finally
    call gina#process#unregister(s:SCHEME, 1)
  endtry
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = a:args.clone()
  let args.params.group = args.pop('--group', '')
  let args.params.opener = args.pop('--opener', 'edit')
  call gina#core#args#extend_path(a:git, args, args.pop(1))
  call gina#core#args#extend_line(a:git, args, args.pop('--line'))
  call gina#core#args#extend_col(a:git, args, args.pop('--col'))
  return args.lock()
endfunction

function! s:call(range, args, mods) abort
  let git = gina#core#get()
  let args = s:build_args(git, a:args)
  let abspath = gina#core#repo#abspath(git, args.params.path)
  let bufname = s:Path.realpath(abspath)
  call gina#core#buffer#open(bufname, {
        \ 'mods': a:mods,
        \ 'group': args.params.group,
        \ 'opener': args.params.opener,
        \ 'cmdarg': args.params.cmdarg,
        \ 'line': args.params.line,
        \ 'col': args.params.col,
        \})
  call gina#core#emitter#emit('command:called', s:SCHEME)
endfunction
