let s:Exception = vital#gina#import('Vim.Exception')


function! gina#command#diff#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)

  let bufname = printf(
        \ 'gina://%s:diff%s/%s',
        \ git.refname,
        \ args.params.cached ? ':cached' : '',
        \ args.params.object,
        \)
  call gina#util#buffer#open(bufname, {
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
  let args.params = {}
  let args.params.async = args.get('--async')
  let args.params.group = args.pop('--group', '')
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.cmdarg = join([
        \ args.pop('^++enc'),
        \ args.pop('^++ff'),
        \])
  let args.params.repository = args.pop('--repository')
  let args.params.cached = args.get('--cached')
  let args.params.commit = args.get(1, '')

  let args.params.path = ''
  let args.params.object = args.params.commit
  if args.params.repository
    let pathlist = []
  else
    let pathlist = args.residual()
    let pathlist = map(
          \ empty(pathlist) ? ['%'] : pathlist,
          \ 'gina#util#relpath(gina#util#expand(v:val))'
          \)
    if len(pathlist) == 1
      let args.params.path = pathlist[0]
      let args.params.object = args.params.commit . ':' . args.params.path
    endif
  endif

  call args.set(1, args.params.commit)
  call args.residual(pathlist)
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
  setlocal filetype=diff
endfunction
