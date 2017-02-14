let s:Path = vital#gina#import('System.Filepath')


function! gina#command#cd#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  execute 'cd' gina#util#fnameescape(s:Path.realpath(args.params.abspath))
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = gina#command#parse_args(a:args)
  let args.params.abspath = gina#core#path#abspath(args.pop(1, '.'))

  return args.lock()
endfunction
