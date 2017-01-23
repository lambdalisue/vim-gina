let s:Argument = vital#gina#import('Argument')
let s:Exception = vital#gina#import('Vim.Exception')
let s:Group = vital#gina#import('Vim.Buffer.Group')
let s:Opener = vital#gina#import('Vim.Buffer.Opener')
let s:WORKTREE = '@@'


function! gina#command#compare#define() abort
  return s:command
endfunction


" Instance -------------------------------------------------------------------
let s:command = {'name': 'compare'}

function! s:command.command(range, qargs, qmods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:qargs)

  let [commit1, commit2] = gina#util#commit#split(
        \ git, args.params.commit
        \)
  if args.params.cached
    let commit1 = empty(commit1) ? 'HEAD' : commit1
    let commit2 = empty(commit2) ? '' : commit2
  else
    let commit1 = empty(commit1) ? '' : commit1
    let commit2 = empty(commit2) ? s:WORKTREE : commit2
  endif
  if args.params.R
    let [commit2, commit1] = [commit1, commit2]
  endif

  silent! windo diffoff!

  let group = s:Group.new()
  let opener1 = args.params.opener
  let opener2 = empty(matchstr(&diffopt, 'vertical'))
        \ ? 'split'
        \ : 'vsplit'
  call s:open(
        \ 'l', args.params.path, commit1, opener1,
        \ args.params.line, args.params.col,
        \ args.params.cmdarg,
        \)
  call gina#util#diffthis()
  call group.add()

  call s:open(
        \ 'r', args.params.path, commit2, opener2,
        \ args.params.line, args.params.col,
        \ args.params.cmdarg,
        \)
  call gina#util#diffthis()
  call group.add({'keep': 1})

  call gina#util#diffupdate()
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, qargs) abort
  let args = s:Argument.new(a:qargs)
  let args.params = {}
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.cmdarg = join([
        \ args.pop('^++enc'),
        \ args.pop('^++ff'),
        \])
  let args.params.line = args.pop('--line')
  let args.params.col = args.pop('--col')
  let args.params.cached = args.get('--cached')
  let args.params.R = args.get('-R')
  let args.params.commit = args.pop(1, '')
  let args.params.path = gina#util#relpath(
        \ gina#util#expand(get(args.residual(), 0, '%'))
        \)
  return args.lock()
endfunction

function! s:open(suffix, path, commit, opener, line, col, cmdarg) abort
  if s:Opener.is_preview_opener(a:opener)
    throw s:Exception.error(printf(
          \ 'An opener "%s" is not allowed.',
          \ a:opener,
          \))
  endif
  if a:commit ==# s:WORKTREE
    execute printf(
          \ 'Gina edit %s %s %s %s %s -- %s',
          \ a:cmdarg,
          \ printf('--group=compare-%s', a:suffix),
          \ gina#util#shellescape(a:opener, '--opener='),
          \ gina#util#shellescape(a:line, '--line='),
          \ gina#util#shellescape(a:col, '--col='),
          \ gina#util#fnameescape(a:path),
          \)
  else
    execute printf(
          \ 'Gina show %s %s %s %s %s %s -- %s',
          \ a:cmdarg,
          \ printf('--group=compare-%s', a:suffix),
          \ gina#util#shellescape(a:opener, '--opener='),
          \ gina#util#shellescape(a:line, '--line='),
          \ gina#util#shellescape(a:col, '--col='),
          \ gina#util#shellescape(a:commit),
          \ gina#util#fnameescape(a:path),
          \)
  endif
endfunction
