function! gina#command#edit#call(range, args, mods) abort
  let git = gina#core#get()
  let args = s:build_args(git, a:args)
  let bufname = args.params.path
  call gina#core#buffer#open(bufname, {
        \ 'mods': a:mods,
        \ 'group': args.params.group,
        \ 'opener': args.params.opener,
        \ 'cmdarg': args.params.cmdarg,
        \ 'line': args.params.line,
        \ 'col': args.params.col,
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = gina#command#parse_args(a:args)
  let args.params = {}
  let args.params.group = args.pop('--group', '')
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.cmdarg = join([
        \ args.pop('^++enc'),
        \ args.pop('^++ff'),
        \])
  let args.params.line = args.pop('--line', v:null)
  let args.params.col = args.pop('--col', v:null)
  let args.params.path = gina#core#repo#abspath(
        \ a:git,
        \ gina#core#repo#expand(get(args.residual(), 0, '%'))
        \)
  return args.lock()
endfunction
