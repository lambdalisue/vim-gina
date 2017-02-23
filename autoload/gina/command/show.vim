let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Path = vital#gina#import('System.Filepath')

let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#show#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let bufname = gina#core#buffer#bufname(git, 'show', {
        \ 'treeish': args.params.treeish,
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
  let args.params.line = args.pop('--line', v:null)
  let args.params.col = args.pop('--col', v:null)
  call gina#core#args#extend_treeish(a:git, args, args.pop(1))
  return args.lock()
endfunction

function! s:init(args) abort
  call gina#core#meta#set('args', a:args)

  if exists('b:gina_initialized')
    return
  endif
  let b:gina_initialized = 1

  setlocal buftype=nowrite
  setlocal bufhidden&
  setlocal noswapfile
  setlocal nomodifiable

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
  call gina#core#writer#assign_content(bufnr('%'), result.content)
  call gina#core#emitter#emit('command:called', s:SCHEME)
  call gina#util#doautocmd('BufRead')
endfunction
