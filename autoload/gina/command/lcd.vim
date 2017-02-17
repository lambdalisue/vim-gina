let s:Path = vital#gina#import('System.Filepath')
let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#lcd#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  execute s:SCHEME gina#util#fnameescape(s:Path.realpath(args.params.abspath))
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = gina#command#parse_args(a:args)
  let args.params.abspath = gina#core#path#abspath(args.pop(1, '.'), a:git.worktree)

  return args.lock()
endfunction
