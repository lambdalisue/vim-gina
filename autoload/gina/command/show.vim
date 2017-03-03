let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Path = vital#gina#import('System.Filepath')

let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#show#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let bufname = gina#core#buffer#bufname(git, s:SCHEME, {
        \ 'treeish': args.params.treeish,
        \ 'params': [
        \   args.params.partial ? '--' : '',
        \ ],
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
  let args = a:args.clone()
  let args.params.group = args.pop('--group', '')
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.partial = !empty(args.residual())
  call gina#core#args#extend_treeish(a:git, args, args.pop(1))
  " Enable --line/--col only when a path has specified
  if args.params.path isnot# v:null
    call gina#core#args#extend_line(a:git, args, args.pop('--line'))
    call gina#core#args#extend_col(a:git, args, args.pop('--col'))
  else
    call args.pop('--line')
    call args.pop('--col')
    let args.params.line = v:null
    let args.params.col = v:null
  endif
  return args.lock()
endfunction

function! s:init(args) abort
  call gina#core#meta#set('args', a:args)

  if exists('b:gina_initialized')
    return
  endif
  let b:gina_initialized = 1

  setlocal buftype=nowrite
  setlocal noswapfile
  setlocal nomodifiable
  if a:args.params.partial
    setlocal bufhidden=wipe
  else
    setlocal bufhidden&
  endif

  augroup gina_command_show_internal
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
    autocmd BufWinEnter <buffer> setlocal buflisted
    autocmd BufWinLeave <buffer> setlocal nobuflisted
  augroup END
endfunction

function! s:reassign_rev(git, args) abort
  let rev = gina#core#treeish#resolve(a:git, a:args.params.rev)
  let treeish = gina#core#treeish#build(rev, a:args.params.path)
  call a:args.set(1, substitute(treeish, '^:0', '', ''))
  return a:args
endfunction

function! s:BufReadCmd() abort
  let git = gina#core#get_or_fail()
  let args = gina#core#meta#get_or_fail('args')
  let args = s:reassign_rev(git, args.clone())
  let result = gina#process#call_or_fail(git, args)
  call gina#core#buffer#assign_cmdarg()
  call gina#core#writer#assign_content(v:null, result.content)
  call gina#core#emitter#emit('command:called', s:SCHEME)
  if args.params.path is# v:null
    setlocal nomodeline
    setfiletype git
  else
    call gina#util#doautocmd('BufRead')
  endif
endfunction
