let s:Path = vital#gina#import('System.Filepath')
let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#cd#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let abspath = gina#core#repo#abspath(git, args.params.path)
  execute s:SCHEME gina#util#fnameescape(s:Path.realpath(abspath))
  call gina#core#emitter#emit('command:called', s:SCHEME)
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = a:args.clone()
  call gina#core#args#extend_path(a:git, args, args.pop(1, '.'))
  return args.lock()
endfunction
