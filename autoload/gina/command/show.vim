let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Path = vital#gina#import('System.Filepath')


function! gina#command#show#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let bufname = gina#core#buffer#bufname(git, 'show', {
        \ 'revision': args.params.revision,
        \ 'relpath': gina#core#repo#relpath(git, args.params.abspath),
        \})
  call gina#core#buffer#open(bufname, {
        \ 'mods': a:mods,
        \ 'group': args.params.group,
        \ 'opener': args.params.opener,
        \ 'cmdarg': args.params.cmdarg,
        \ 'line': args.params.line,
        \ 'col': args.params.col,
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
  let args.params.line = args.pop('--line', v:null)
  let args.params.col = args.pop('--col', v:null)

  let args.params.abspath = gina#core#path#abspath(get(args.residual(), 0, '%'))
  let args.params.revision = args.pop(1, gina#core#buffer#param('%', 'revision'))

  if empty(args.params.abspath)
    call args.set(1, args.params.revision)
  else
    call args.set(1, printf('%s:%s',
          \ args.params.revision,
          \ gina#core#repo#relpath(a:git, args.params.abspath)
          \))
  endif
  call args.residual([])
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
  let git = gina#core#get_or_fail()
  let args = gina#core#meta#get_or_fail('args')
  let result = gina#process#call(git, args)
  if result.status
    throw gina#process#error(result)
  endif
  call gina#core#buffer#assign_content(result.content)
  call gina#core#emitter#emit('command:called', args.get(0))
  call gina#util#doautocmd('BufRead')
endfunction
