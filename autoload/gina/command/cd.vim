let s:Path = vital#gina#import('System.Filepath')

let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#cd#call(range, args, mods) abort
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
  let args.params.local = args.get('--local')
  call gina#core#args#extend_path(a:git, args, args.pop(1, v:null))
  return args.lock()
endfunction

function! s:call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let path = gina#util#get(args.params, 'path', '')
  let abspath = gina#core#repo#abspath(git, path)
  let command = args.params.local ? 'lcd' : 'cd'
  execute command gina#util#fnameescape(s:Path.realpath(abspath))
  call gina#core#emitter#emit('command:called', s:SCHEME)
endfunction

