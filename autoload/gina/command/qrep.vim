let s:Guard = vital#gina#import('Vim.Guard')
let s:Path = vital#gina#import('System.Filepath')

let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#qrep#call(range, args, mods) abort
  call gina#core#options#help_if_necessary(a:args, s:get_options())
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)

  call gina#util#doautocmd('QuickfixCmdPre')
  let result = gina#process#call(git, args)
  let guard = s:Guard.store(['&more'])
  try
    set nomore
    call gina#process#inform(result)

    " XXX: Support rev
    " 1. Globally enable BufReadCmd for gina://xxx:show/...
    " 2. Use gina://xxx:show/... to open a content in a rev
    let rev = ''
    let residual = args.residual()

    let items = map(
          \ result.content,
          \ 's:parse_record(git, v:val, rev, residual)',
          \)
    call setqflist(
          \ filter(items, '!empty(v:val)'),
          \ args.params.action,
          \)
  finally
    call guard.restore()
  endtry
  call gina#util#doautocmd('QuickfixCmdPost')
  if !args.params.bang
    cc
  endif
  call gina#core#emitter#emit('command:called', s:SCHEME)
endfunction

function! gina#command#qrep#complete(arglead, cmdline, cursorpos) abort
  let args = gina#core#args#new(matchstr(a:cmdline, '^.*\ze .*'))
  if a:cmdline =~# '\s--\s'
    return gina#complete#filename#any(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead[0] ==# '-' || !empty(args.get(2))
    let options = s:get_options()
    return options.complete(a:arglead, a:cmdline, a:cursorpos)
  endif
  return gina#complete#commit#any(a:arglead, a:cmdline, a:cursorpos)
endfunction


" Private --------------------------------------------------------------------
function! s:get_options() abort
  if exists('s:options') && !g:gina#develop
    return s:options
  endif
  let s:options = gina#core#options#new()
  call s:options.define(
        \ '-h|--help',
        \ 'Show this help.',
        \)
  call s:options.define(
        \ '--opener=',
        \ 'A Vim command to open a new buffer.',
        \ ['edit', 'split', 'vsplit', 'tabedit', 'pedit'],
        \)
  call s:options.define(
        \ '--group=',
        \ 'A window group name used for the buffer.',
        \)
  call s:options.define(
        \ '--cached',
        \ 'Search in index instead of in the work tree',
        \)
  call s:options.define(
        \ '--no-index',
        \ 'Find in contents not managed by git',
        \)
  call s:options.define(
        \ '--untracked',
        \ 'Search in both tracked and untracked files',
        \)
  call s:options.define(
        \ '--exclude-standard',
        \ 'Ignore files specified via .gitignore',
        \)
  call s:options.define(
        \ '-v|--invert-match',
        \ 'Show non-matching lines',
        \)
  call s:options.define(
        \ '-i|--ignore-case',
        \ 'Case insensitive matching',
        \)
  call s:options.define(
        \ '-w|--word-regexp',
        \ 'Match patterns only at word boundaries',
        \)
  call s:options.define(
        \ '-a|--text',
        \ 'Process binary files as text',
        \)
  call s:options.define(
        \ '-I',
        \ 'Don''t match patterns in binary files',
        \)
  call s:options.define(
        \ '--textconv',
        \ 'Process binary files with textconv filters',
        \)
  call s:options.define(
        \ '--max-depth=',
        \ 'Descend at most <depth> levels',
        \)
  call s:options.define(
        \ '-E|--extended-regexp',
        \ 'Use extended POSIC regular expression',
        \)
  call s:options.define(
        \ '-G|--basic-regexp',
        \ 'Use basic POSIX regular expression',
        \)
  call s:options.define(
        \ '-F|--fixed-string',
        \ 'Interpret patterns as fixed strings',
        \)
  call s:options.define(
        \ '-P|--perl-regexp',
        \ 'Use Perl-compatible regular expression',
        \)
  call s:options.define(
        \ '--break',
        \ 'Print empty line between matches from different files',
        \)
  call s:options.define(
        \ '-C|--context=',
        \ 'Show <n> context lines before and after matches',
        \)
  call s:options.define(
        \ '-B|--before-context=',
        \ 'Show <n> context lines before matches',
        \)
  call s:options.define(
        \ '-A|--after-context=',
        \ 'Show <n> context lines after matches',
        \)
  call s:options.define(
        \ '--threads=',
        \ 'Use <n> worker threads',
        \)
  call s:options.define(
        \ '-p|--show-function',
        \ 'Show a line with the function name before matches',
        \)
  call s:options.define(
        \ '-W|--function-context',
        \ 'Show the surrounding function',
        \)
  call s:options.define(
        \ '-f',
        \ 'Read patterns from file',
        \)
  call s:options.define(
        \ '-e',
        \ 'Match <pattern>',
        \)
  call s:options.define(
        \ '--and|--or|--not',
        \ 'Combine patterns specified with -e',
        \)
  call s:options.define(
        \ '--all-match',
        \ 'Show only matches from files that match all patterns',
        \)
  call s:options.define(
        \ '--action',
        \ 'An action which is specified to setqflist()',
        \)
  return s:options
endfunction

function! s:build_args(git, args) abort
  let args = a:args.clone()
  let args.params.bang = args.get(0) =~# '!$'
  let args.params.action = args.pop('--action', ' ')
  let args.params.pattern = args.pop(1, '')

  " Check if available grep patterns has specified and ask if not
  if empty(args.params.pattern) && !(args.has('-e') || args.has('-f'))
    let pattern = gina#core#console#ask('Pattern: ')
    if empty(pattern)
      throw gina#core#exception#info('Cancel')
    endif
    let args.params.pattern = pattern
  endif

  call args.set('--line-number', 1)
  call args.set('--color', 'always')
  call args.set(0, 'grep')
  call args.set(1, args.params.pattern)
  return args.lock()
endfunction

function! s:parse_record(git, record, rev, residual) abort
  " Parse record to make a gina candidate and translate it to a quickfix item
  let candidate = gina#command#grep#parse_record(
        \ a:record, a:rev, a:residual,
        \)
  if empty(candidate)
    return {}
  endif
  return {
        \ 'filename': s:Path.realpath(
        \   gina#core#repo#abspath(a:git, candidate.path)
        \ ),
        \ 'text': candidate.word,
        \ 'lnum': candidate.line,
        \ 'col': candidate.col,
        \}
endfunction
