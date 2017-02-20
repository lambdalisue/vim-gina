let s:Path = vital#gina#import('System.Filepath')
let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#edit#call(range, args, mods) abort
  let git = gina#core#get()
  let args = s:build_args(git, a:args)
  let bufname = s:Path.realpath(args.params.abspath)
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


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = a:args.clone()
  let args.params.group = args.pop('--group', '')
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.line = args.pop('--line', v:null)
  let args.params.col = args.pop('--col', v:null)
  let args.params.abspath = gina#core#path#abspath(get(args.residual(), 0, '%'))
  return args.lock()
endfunction
