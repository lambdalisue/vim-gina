function! gina#command#cd#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  execute 'cd' gina#util#fnameescape(args.params.path)
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = gina#command#parse_args(a:args)
  let args.params = {}
  let args.params.path = args.pop(1, '.')

  if !empty(args.params.path)
    let args.params.path = gina#core#repo#abspath(
          \ a:git,
          \ gina#core#repo#expand(args.params.path)
          \)
  endif

  return args.lock()
endfunction
