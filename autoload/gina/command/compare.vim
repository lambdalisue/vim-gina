let s:Group = vital#gina#import('Vim.Buffer.Group')
let s:Opener = vital#gina#import('Vim.Buffer.Opener')

let s:SCHEME = gina#command#scheme(expand('<sfile>'))
let s:WORKTREE = '@@'


function! gina#command#compare#call(range, args, mods) abort
  call gina#core#options#help_if_necessary(a:args, s:get_options())
  call gina#process#register(s:SCHEME, 1)
  try
    call s:call(a:range, a:args, a:mods)
  finally
    call gina#process#unregister(s:SCHEME, 1)
  endtry
endfunction

function! gina#command#compare#complete(arglead, cmdline, cursorpos) abort
  let args = gina#core#args#new(matchstr(a:cmdline, '^.*\ze .*'))
  if a:arglead[0] ==# '-'
    let options = s:get_options()
    return options.complete(a:arglead, a:cmdline, a:cursorpos)
  endif
  return gina#complete#common#treeish(a:arglead, a:cmdline, a:cursorpos)
endfunction


" Private --------------------------------------------------------------------
function! s:get_options() abort
  let options = gina#core#options#new()
  call options.define(
        \ '-h|--help',
        \ 'Show this help.',
        \)
  call options.define(
        \ '--opener=',
        \ 'A Vim command to open a new buffer.',
        \ ['edit', 'split', 'vsplit', 'tabedit', 'pedit'],
        \)
  call options.define(
        \ '--group1=',
        \ 'A window group name used for the 1st buffer.',
        \)
  call options.define(
        \ '--group2=',
        \ 'A window group name used for the 2nd buffer.',
        \)
  call options.define(
        \ '--line',
        \ 'An initial line number.',
        \)
  call options.define(
        \ '--col',
        \ 'An initial column number.',
        \)
  call options.define(
        \ '--cached',
        \ 'Compare to the index rather than the working tree',
        \)
  call options.define(
        \ '-R',
        \ 'Reverse the buffer order',
        \)
  return options
endfunction

function! s:build_args(git, args) abort
  let args = a:args.clone()
  let args.params.groups = [
        \ args.pop('--group1', 'compare-l'),
        \ args.pop('--group2', 'compare-r'),
        \]
  let args.params.opener = args.pop('--opener', 'tabnew')
  let args.params.cached = args.get('--cached')
  let args.params.R = args.get('-R')

  call gina#core#args#extend_treeish(a:git, args, args.pop(1, ':'))
  call gina#core#args#extend_line(a:git, args, args.pop('--line'))
  call gina#core#args#extend_col(a:git, args, args.pop('--col'))
  if empty(args.params.path)
    throw gina#core#exception#warn(printf(
          \ 'No filename is specified. Did you mean "Gina compare %s:"?',
          \ args.params.rev,
          \))
  endif
  return args.lock()
endfunction

function! s:call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let mods = gina#util#contain_direction(a:mods)
        \ ? 'keepalt ' . a:mods
        \ : join(['keepalt', 'rightbelow', a:mods])
  let group = s:Group.new()

  let [rev1, rev2] = gina#core#treeish#split(args.params.rev)
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

  " Validate if all requirements exist
  if rev1 != s:WORKTREE
    call gina#core#treeish#validate(git, rev1, args.params.path)
  endif
  if rev2 != s:WORKTREE
    call gina#core#treeish#validate(git, rev2, args.params.path)
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

function! s:open(n, mods, opener, rev, params) abort
  if s:Opener.is_preview_opener(a:opener)
    throw gina#core#exception#warn(printf(
          \ 'An opener "%s" is not allowed.',
          \ a:opener,
          \))
  endif
  if a:rev ==# s:WORKTREE
    execute printf(
          \ '%s Gina edit %s %s %s %s %s %s',
          \ a:mods,
          \ a:params.cmdarg,
          \ gina#util#shellescape(a:opener, '--opener='),
          \ gina#util#shellescape(a:params.groups[a:n], '--group='),
          \ gina#util#shellescape(a:params.line, '--line='),
          \ gina#util#shellescape(a:params.col, '--col='),
          \ gina#util#shellescape(a:params.path),
          \)
  else
    let treeish = gina#core#treeish#build(a:rev, a:params.path)
    execute printf(
          \ '%s Gina show %s %s %s %s %s %s',
          \ a:mods,
          \ a:params.cmdarg,
          \ gina#util#shellescape(a:opener, '--opener='),
          \ gina#util#shellescape(a:params.groups[a:n], '--group='),
          \ gina#util#shellescape(a:params.line, '--line='),
          \ gina#util#shellescape(a:params.col, '--col='),
          \ gina#util#shellescape(treeish),
          \)
  endif
endfunction
