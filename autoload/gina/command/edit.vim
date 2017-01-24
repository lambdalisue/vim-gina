function! gina#command#edit#define() abort
  return s:command
endfunction


" Instance -------------------------------------------------------------------
let s:command = {}

function! s:command.command(range, qargs, qmods) abort
  let git = gina#core#get()
  let args = s:build_args(git, a:qargs)
  let bufname = args.params.path
  call gina#util#buffer#open(bufname, {
        \ 'mods': a:qmods,
        \ 'group': args.params.group,
        \ 'opener': args.params.opener,
        \ 'cmdarg': args.params.cmdarg,
        \ 'line': args.params.line,
        \ 'col': args.params.col,
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, qargs) abort
  let args = gina#command#parse(a:qargs)
  let args.params = {}
  let args.params.group = args.pop('--group', '')
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.cmdarg = join([
        \ args.pop('^++enc'),
        \ args.pop('^++ff'),
        \])
  let args.params.line = args.pop('--line', v:null)
  let args.params.col = args.pop('--col', v:null)
  let args.params.path = gina#util#abspath(
        \ gina#util#expand(get(args.residual(), 0, '%'))
        \)
  return args.lock()
endfunction
