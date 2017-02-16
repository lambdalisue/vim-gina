let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Path = vital#gina#import('System.Filepath')


function! gina#command#info#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let bufname = gina#core#buffer#bufname(git, 'info', {
        \ 'revision': args.params.revision,
        \ 'relpath': gina#core#repo#relpath(git, args.params.abspath),
        \})
  call gina#core#buffer#open(bufname, {
        \ 'mods': a:mods,
        \ 'group': args.params.group,
        \ 'opener': args.params.opener,
        \ 'cmdarg': args.params.cmdarg,
        \ 'callback': {
        \   'fn': function('s:init'),
        \   'args': [args],
        \ }
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = gina#command#parse_args(a:args)
  let args.params.group = args.pop('--group', '')
  let args.params.opener = args.pop('--opener', 'edit')

  let pathlist = copy(args.residual())
  if empty(pathlist)
    let args.params.revision = args.get(1, gina#core#buffer#param('%', 'revision'))
    let args.params.abspath = gina#core#path#abspath('%')
    let pathlist = [args.params.abspath]
  elseif len(pathlist) == 1
    let args.params.revision = args.get(1, gina#core#buffer#param(pathlist[0], 'revision'))
    let args.params.abspath = gina#core#path#abspath(pathlist[0])
    let pathlist = [args.params.abspath]
  else
    let args.params.revision = args.get(1, '')
    let args.params.abspath = ''
    let pathlist = map(pathlist, 'gina#core#path#abspath(v:val)')
  endif

  call args.set(0, 'show')
  call args.set(1, args.params.revision)
  call args.residual(pathlist)
  return args.lock()
endfunction

function! s:init(args) abort
  call gina#core#meta#set('args', a:args)

  if exists('b:gina_initialized')
    return
  endif
  let b:gina_initialized = 1

  setlocal buftype=nowrite
  setlocal bufhidden=unload
  setlocal noswapfile
  setlocal nomodifiable

  augroup gina_internal_command
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
  augroup END
endfunction

function! s:BufReadCmd() abort
  call gina#process#exec(
        \ gina#core#get_or_fail(),
        \ gina#core#meta#get_or_fail('args'),
        \)
  setlocal filetype=git
endfunction
