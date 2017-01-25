let s:Group = vital#gina#import('Vim.Buffer.Group')
let s:Opener = vital#gina#import('Vim.Buffer.Opener')
let s:WORKTREE = '@@'


function! gina#command#compare#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)

  let [commit1, commit2] = gina#core#commit#split(
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
  call s:open(0, a:mods, opener1, commit1, args.params)
  call gina#util#diffthis()
  call group.add()

  call s:open(1, a:mods, opener2, commit2, args.params)
  call gina#util#diffthis()
  call group.add({'keep': 1})

  call gina#util#diffupdate()
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = gina#command#parse_args(a:args)
  let args.params = {}
  let args.params.async = args.pop('--async')
  let args.params.groups = [
        \ args.pop('--group1', 'compare-l'),
        \ args.pop('--group2', 'compare-r'),
        \]
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

function! s:open(n, mods, opener, commit, params) abort
  if s:Opener.is_preview_opener(a:opener)
    throw gina#core#exception#error(printf(
          \ 'An opener "%s" is not allowed.',
          \ a:opener,
          \))
  endif
  if a:commit ==# s:WORKTREE
    execute printf(
          \ '%s Gina %s edit %s %s %s %s %s -- %s',
          \ a:mods,
          \ a:params.async ? '--async' : '',
          \ a:params.cmdarg,
          \ gina#util#shellescape(a:opener, '--opener='),
          \ gina#util#shellescape(a:params.groups[a:n], '--group='),
          \ gina#util#shellescape(a:params.line, '--line='),
          \ gina#util#shellescape(a:params.col, '--col='),
          \ gina#util#fnameescape(a:params.path),
          \)
  else
    execute printf(
          \ '%s Gina %s show %s %s %s %s %s %s -- %s',
          \ a:mods,
          \ a:params.async ? '--async' : '',
          \ a:params.cmdarg,
          \ gina#util#shellescape(a:opener, '--opener='),
          \ gina#util#shellescape(a:params.groups[a:n], '--group='),
          \ gina#util#shellescape(a:params.line, '--line='),
          \ gina#util#shellescape(a:params.col, '--col='),
          \ gina#util#shellescape(a:commit),
          \ gina#util#fnameescape(a:params.path),
          \)
  endif
endfunction
