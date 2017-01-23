let s:Argument = vital#gina#import('Argument')
let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Emitter = vital#gina#import('Emitter')
let s:Exception = vital#gina#import('Vim.Exception')


function! gina#command#show#define() abort
  return s:command
endfunction


" Instance -------------------------------------------------------------------
let s:command = {}

function! s:command.command(range, qargs, qmods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:qargs)
  let bufname = printf(
        \ 'gina://%s:show/%s',
        \ git.refname,
        \ args.params.object,
        \)
  call gina#util#buffer#open(bufname, {
        \ 'group': args.params.group,
        \ 'opener': args.params.opener,
        \ 'line': args.params.line,
        \ 'col': args.params.col,
        \})
endfunction

function! s:command.BufReadCmd() abort
  let git = gina#core#get_or_fail()
  let args = s:build_args_from_params(
        \ gina#util#params(expand('<afile>'))
        \)
  call s:init(args)
  call s:BufReadCmd()
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, qargs) abort
  let args = s:Argument.new(a:qargs)
  let args.params = {}
  let args.params.repository = args.pop('--repository')
  let args.params.group = args.pop('--group', '')
  let args.params.opener = args.pop('--opener', 'edit')
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

  call args.set(1, args.params.object)
  call args.residual([])
  return args.lock()
endfunction

function! s:build_args_from_params(params) abort
  let args = s:Argument.new('show')
  if empty(a:params.path)
    let object = a:params.commit
  else
    let object = printf('%s:%s', a:params.commit, a:params.path)
  endif
  call args.set(1, object)
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
  setlocal nomodifiable
endfunction

function! s:BufReadCmd() abort
  let result = gina#process#call(
        \ gina#core#get_or_fail(),
        \ gina#util#meta#get_or_fail('args').raw,
        \)
  call s:Buffer.edit_content(result.content)

  let params = gina#util#params('%')
  if empty(params.path)
    setlocal filetype=git
  else
    call gina#util#doautocmd('BufRead')
  endif
endfunction
