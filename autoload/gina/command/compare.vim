let s:Group = vital#gina#import('Vim.Buffer.Group')
let s:Opener = vital#gina#import('Vim.Buffer.Opener')
let s:WORKTREE = '@@'


function! gina#command#compare#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)

  let [revision1, revision2] = gina#core#revision#split(
        \ git, args.params.revision
        \)
  if args.params.cached
    let revision1 = empty(revision1) ? 'HEAD' : revision1
    let revision2 = empty(revision2) ? '' : revision2
  else
    let revision1 = empty(revision1) ? '' : revision1
    let revision2 = empty(revision2) ? s:WORKTREE : revision2
  endif
  if args.params.R
    let [revision2, revision1] = [revision1, revision2]
  endif

  silent! windo diffoff!

  let group = s:Group.new()
  let opener1 = args.params.opener
  let opener2 = empty(matchstr(&diffopt, 'vertical'))
        \ ? 'split'
        \ : 'vsplit'
  call s:open(0, a:mods, opener1, revision1, args.params)
  call gina#util#diffthis()
  call group.add()

  call s:open(1, a:mods, opener2, revision2, args.params)
  call gina#util#diffthis()
  call group.add({'keep': 1})

  call gina#util#diffupdate()
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = gina#command#parse_args(a:args)
  let args.params.groups = [
        \ args.pop('--group1', 'compare-l'),
        \ args.pop('--group2', 'compare-r'),
        \]
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.line = args.pop('--line')
  let args.params.col = args.pop('--col')
  let args.params.cached = args.get('--cached')
  let args.params.R = args.get('-R')
  let args.params.abspath = gina#core#path#abspath(a:git, get(args.residual(), 0, '%'))
  let args.params.revision = args.pop(1, gina#core#buffer#param('%', 'revision', ''))
  return args.lock()
endfunction

function! s:open(n, mods, opener, revision, params) abort
  if s:Opener.is_preview_opener(a:opener)
    throw gina#core#exception#error(printf(
          \ 'An opener "%s" is not allowed.',
          \ a:opener,
          \))
  endif
  if a:revision ==# s:WORKTREE
    execute printf(
          \ '%s Gina %s edit %s %s %s %s %s -- %s',
          \ a:mods,
          \ a:params.async ? '--async' : '',
          \ a:params.cmdarg,
          \ gina#util#fnameescape(a:opener, '--opener='),
          \ gina#util#fnameescape(a:params.groups[a:n], '--group='),
          \ gina#util#fnameescape(a:params.line, '--line='),
          \ gina#util#fnameescape(a:params.col, '--col='),
          \ gina#util#fnameescape(a:params.abspath),
          \)
  else
    execute printf(
          \ '%s Gina %s show %s %s %s %s %s %s -- %s',
          \ a:mods,
          \ a:params.async ? '--async' : '',
          \ a:params.cmdarg,
          \ gina#util#fnameescape(a:opener, '--opener='),
          \ gina#util#fnameescape(a:params.groups[a:n], '--group='),
          \ gina#util#fnameescape(a:params.line, '--line='),
          \ gina#util#fnameescape(a:params.col, '--col='),
          \ gina#util#fnameescape(a:revision),
          \ gina#util#fnameescape(a:params.abspath),
          \)
  endif
endfunction
