let s:Guard = vital#gina#import('Vim.Guard')
let s:Path = vital#gina#import('System.Filepath')

let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#qrep#call(range, args, mods) abort
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
          \ 's:parse_record(git, 1 + v:key, v:val, rev, residual)',
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


" Private --------------------------------------------------------------------
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

function! s:parse_record(git, lnum, record, rev, residual) abort
  " Parse record to make a gina candidate and translate it to a quickfix item
  let candidate = gina#command#grep#parse_record(
        \ a:lnum, a:record, a:rev, a:residual,
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
