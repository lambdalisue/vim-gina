let s:Path = vital#gina#import('System.Filepath')
let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#cd#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  execute s:SCHEME gina#util#fnameescape(s:Path.realpath(args.params.abspath))
  call gina#core#emitter#emit('command:called', s:SCHEME)
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = a:args.clone()
  let args.params.abspath = gina#core#path#abspath(args.pop(1, '.'), a:git.worktree)

  return args.lock()
endfunction
