let s:Argument = vital#gina#import('Argument')
let s:Emitter = vital#gina#import('Emitter')
let s:Exception = vital#gina#import('Vim.Exception')


function! gina#command#show#command(range, qargs, qmods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:qargs)
  let bufname = printf(
        \ 'gina://%s:show%s/%s',
        \ git.refname,
        \ args.params.patch ? ':patch' : '',
        \ args.params.object,
        \)
  let selection = gina#util#selection#from(
        \ bufname,
        \ args.params.selection,
        \)
  call gina#util#buffer#open(bufname, {
        \ 'opener': args.params.opener,
        \ 'selection': selection,
        \})
endfunction

function! gina#command#show#BufReadCmd() abort
  let git = gina#core#get_or_fail()
  let args = s:build_args_from_params(
        \ gina#util#path#params(expand('<afile>'))
        \)
  call s:init(args)
  call s:BufReadCmd()
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, qargs) abort
  let args = s:Argument.new(a:qargs)
  let args.params.repository = args.pop('--repository')
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.selection = args.pop('--selection', '')
  let args.params.patch = args.pop('--patch')
  let args.params.commit = gina#util#commit#resolve(
        \ a:git, args.pop_p(1, '')
        \)

  if args.params.repository
    let args.params.path = ''
    let args.params.object = args.params.commit
  else
    let args.params.path = gina#util#path#relpath(
          \ a:git,
          \ gina#util#path#expand(get(args.list_r(), 0, '%'))
          \)
    let args.params.object = args.params.commit . ':' . args.params.path
  endif

  call args.set_p(1, args.params.object)
  return args.lock()
endfunction

function! s:build_args_from_params(params) abort
  let args = s:Argument.new('show')
  if empty(a:params.path)
    let object = a:params.commit
  else
    let object = printf('%s:%s', a:params.commit, a:params.path)
  endif
  call args.set_p(1, object)
  return args.lock()
endfunction

function! s:init(args) abort
  call gina#util#meta#set('args', a:args)

  if exists('b:gina_initialized')
    return
  endif
  let b:gina_initialized = 1

  setlocal buftype=acwrite
  setlocal bufhidden=unload
  setlocal modifiable
endfunction

function! s:BufReadCmd() abort
  let git = gina#core#get_or_fail()
  let args = gina#util#meta#get_or_fail('args')

  call gina#util#command#call(git, args.raw)

  let params = gina#util#path#params('%')
  if empty(params.path)
    setlocal filetype=git
  else
    call gina#util#doautocmd('BufRead')
  endif
endfunction
