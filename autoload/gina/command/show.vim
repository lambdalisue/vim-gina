let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Exception = vital#gina#import('Vim.Exception')


function! gina#command#show#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let bufname = printf(
        \ 'gina://%s:show/%s',
        \ git.refname,
        \ args.params.object,
        \)
  call gina#util#buffer#open(bufname, {
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
  let args.params = {}
  let args.params.async = args.pop('--async')
  let args.params.group = args.pop('--group', '')
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.cmdarg = join([
        \ args.pop('^++enc'),
        \ args.pop('^++ff'),
        \])
  let args.params.repository = args.pop('--repository')
  let args.params.line = args.pop('--line', v:null)
  let args.params.col = args.pop('--col', v:null)
  let args.params.commit = gina#util#commit#resolve(
        \ a:git, args.pop(1, '')
        \)

  if args.params.repository
    let args.params.path = ''
    let args.params.object = args.params.commit
  else
    let args.params.path = gina#util#relpath(
          \ gina#util#expand(get(args.residual(), 0, '%'))
          \)
    let args.params.object = args.params.commit . ':' . args.params.path
  endif
  " NOTE:
  " 'git show {commit}:' shows tree but I assumed that nobody want to see that
  let args.params.object = substitute(args.params.object, ':$', '', '')

  call args.set(1, args.params.object)
  call args.residual([])
  return args.lock()
endfunction

function! s:init(args) abort
  call gina#util#meta#set('args', a:args)

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
        \ gina#util#meta#get_or_fail('args'),
        \)
  let params = gina#util#params('%')
  if empty(params.path)
    setlocal filetype=git
  else
    call gina#util#doautocmd('BufRead')
  endif
endfunction
