let s:Group = vital#gina#import('Vim.Buffer.Group')
let s:Opener = vital#gina#import('Vim.Buffer.Opener')
let s:SCHEME = gina#command#scheme(expand('<sfile>'))
let s:WORKTREE = '@@'


function! gina#command#compare#call(range, args, mods) abort
  call gina#process#register('compare', 1)
  try
    call s:call(a:range, a:args, a:mods)
  finally
    call gina#process#unregister('compare', 1)
  endtry
endfunction


" Private --------------------------------------------------------------------
function! s:call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let mods = gina#util#contain_direction(a:mods)
        \ ? a:mods
        \ : join(['rightbelow', a:mods])
  let group = s:Group.new()

  let [rev1, rev2] = gina#core#rev#split(
        \ git, args.params.rev
        \)
  if args.params.cached
    let rev1 = empty(rev1) ? 'HEAD' : rev1
    let rev2 = empty(rev2) ? ':0' : rev2
  else
    let rev1 = empty(rev1) ? ':0' : rev1
    let rev2 = empty(rev2) ? s:WORKTREE : rev2
  endif
  if args.params.R
    let [rev2, rev1] = [rev1, rev2]
  endif

  diffoff!
  let opener1 = args.params.opener
  let opener2 = empty(matchstr(&diffopt, 'vertical'))
        \ ? 'split'
        \ : 'vsplit'
  call s:open(0, mods, opener1, rev1, args.params)
  call gina#util#diffthis()
  call group.add()

  call s:open(1, mods, opener2, rev2, args.params)
  call gina#util#diffthis()
  call group.add({'keep': 1})

  call gina#util#diffupdate()
  normal! zm
  call gina#core#emitter#emit('command:called', s:SCHEME)
endfunction

function! s:build_args(git, args) abort
  let args = a:args.clone()
  let args.params.groups = [
        \ args.pop('--group1', 'compare-l'),
        \ args.pop('--group2', 'compare-r'),
        \]
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.line = args.pop('--line')
  let args.params.col = args.pop('--col')
  let args.params.cached = args.get('--cached')
  let args.params.R = args.get('-R')
  let args.params.abspath = gina#core#path#abspath(get(args.residual(), 0, '%'))
  let args.params.rev = args.pop(1, gina#core#buffer#param('%', 'rev', ''))
  return args.lock()
endfunction

function! s:open(n, mods, opener, rev, params) abort
  if s:Opener.is_preview_opener(a:opener)
    throw gina#core#exception#error(printf(
          \ 'An opener "%s" is not allowed.',
          \ a:opener,
          \))
  endif
  if a:rev ==# s:WORKTREE
    execute printf(
          \ '%s Gina edit %s %s %s %s %s -- %s',
          \ a:mods,
          \ a:params.cmdarg,
          \ gina#util#shellescape(a:opener, '--opener='),
          \ gina#util#shellescape(a:params.groups[a:n], '--group='),
          \ gina#util#shellescape(a:params.line, '--line='),
          \ gina#util#shellescape(a:params.col, '--col='),
          \ gina#util#shellescape(a:params.abspath),
          \)
  else
    execute printf(
          \ '%s Gina show %s %s %s %s %s %s -- %s',
          \ a:mods,
          \ a:params.cmdarg,
          \ gina#util#shellescape(a:opener, '--opener='),
          \ gina#util#shellescape(a:params.groups[a:n], '--group='),
          \ gina#util#shellescape(a:params.line, '--line='),
          \ gina#util#shellescape(a:params.col, '--col='),
          \ gina#util#shellescape(a:rev),
          \ gina#util#shellescape(a:params.abspath),
          \)
  endif
endfunction
