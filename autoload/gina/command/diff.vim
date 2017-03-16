let s:SCHEME = gina#command#scheme(expand('<sfile>'))
let s:ALLOWED_OPTIONS = [
      \ '--opener=',
      \ '--group=',
      \ '--cached',
      \ '--no-index',
      \ '-p', '-u', '--patch',
      \ '-s', '--no-patch',
      \ '-U', '--unified=',
      \ '--raw',
      \ '--patch-with-raw',
      \ '--minimal',
      \ '--patience',
      \ '--histogram',
      \ '--diff-algorithm=',
      \ '--stat',
      \ '--stat-width=',
      \ '--stat-count=',
      \ '--numstat',
      \ '--shortstat',
      \ '--dirstat',
      \ '--summary',
      \ '--patch-with-stat',
      \ '--name-only',
      \ '--name-status',
      \ '--submodule',
      \ '--word-diff-regex=',
      \ '--no-renames',
      \ '--check',
      \ '--full-index',
      \ '--binary',
      \ '--abbrev',
      \ '-B', '--break-rewrites',
      \ '-M', '--find-renames',
      \ '-C', '--find-copies',
      \ '--find-copies-header',
      \ '-D', '--irreversible-delete',
      \ '-l',
      \ '--diff-filter=',
      \ '-S',
      \ '-G',
      \ '--pickaxe-all',
      \ '--pickaxe-regex',
      \ '-O',
      \ '-R',
      \ '--relative',
      \ '-a', '--text',
      \ '--ignore-space-at-eol',
      \ '-b', '--ignore-space-change',
      \ '-w', '--ignore-all-space',
      \ '--ignore-blank-lines',
      \ '--inter-hunk-context=',
      \ '-W', '--function-context',
      \ '--ext-diff',
      \ '--no-ext-diff',
      \ '--textconv', '--no-textconv',
      \ '--ignore-submodules',
      \ '--src-prefix=',
      \ '--dst-prefix=',
      \ '--no-prefix',
      \ '--line-prefix=',
      \ '--ita-invisible-in-index',
      \]


function! gina#command#diff#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)

  let bufname = gina#core#buffer#bufname(git, s:SCHEME, {
        \ 'treeish': args.params.treeish,
        \ 'params': [
        \   args.params.cached ? 'cached' : '',
        \   args.params.R ? 'R' : '',
        \   args.params.partial ? '--' : '',
        \ ],
        \})
  call gina#core#buffer#open(bufname, {
        \ 'mods': a:mods,
        \ 'group': args.params.group,
        \ 'opener': args.params.opener,
        \ 'cmdarg': args.params.cmdarg,
        \ 'callback': {
        \   'fn': function('s:init'),
        \   'args': [args],
        \ }
        \})
endfunction

function! gina#command#diff#complete(arglead, cmdline, cursorpos) abort
  let args = gina#core#args#new(matchstr(a:cmdline, '^.*\ze .*'))
  if a:arglead =~# '^--opener='
    return gina#complete#common#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^\%(--diff-algorithm=\)'
    let leading = matchstr(a:arglead, '^--diff-algorithm=')
    return gina#util#filter(a:arglead, map(
          \ ['patience', 'minimal', 'histogram', 'myers'],
          \ 'leading . v:val'
          \))
  elseif a:arglead =~# '^\%(--dirstat=\)'
    let leading = matchstr(a:arglead, '^--dirstat=')
    let dirstat = matchstr(a:arglead, '^--dirstat=\zs\%([^,]\+,\)*[^,]*')
    let candidates = filter(
          \ ['changes', 'lines', 'files', 'cumulative'],
          \ 'dirstat !~# ''\<'' . v:val . ''\>''',
          \)
    return gina#util#filter(a:arglead, map(
          \ candidates, 'leading . dirstat . v:val'
          \))
  elseif a:arglead =~# '^\%(--submodule=\)'
    let leading = matchstr(a:arglead, '^--submodule=')
    return gina#util#filter(a:arglead, map(
          \ ['short', 'log', 'diff'],
          \ 'leading . v:val'
          \))
  elseif a:arglead =~# '^\%(--diff-filter=\)'
    let leading = matchstr(a:arglead, '^--diff-filter=[ACDMRTUXB]*')
    return gina#util#filter(a:arglead, map(
          \ split('ACDMRTUXB', '\zs'),
          \ 'leading . v:val'
          \))
  elseif a:arglead =~# '^\%(--ignore-submodules=\)'
    let leading = matchstr(a:arglead, '^--ignore-submodules=')
    return gina#util#filter(a:arglead, map(
          \ ['none', 'untracked', 'dirty', 'all'],
          \ 'leading . v:val'
          \))
  elseif a:cmdline =~# '\s--\s'
    return gina#complete#filename#any(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead[0] ==# '-'
    return gina#util#filter(a:arglead, s:ALLOWED_OPTIONS)
  endif
  return gina#complete#common#treeish(a:arglead, a:cmdline, a:cursorpos)
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = a:args.clone()
  let args.params.group = args.pop('--group', '')
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.cached = args.get('--cached')
  let args.params.R = args.get('-R')
  let args.params.partial = !empty(args.residual())

  call gina#core#args#extend_treeish(a:git, args, args.pop(1))
  call args.set(1, args.params.rev)
  if args.params.path isnot# v:null
    call args.residual([args.params.path] + args.residual())
  endif
  return args.lock()
endfunction

function! s:init(args) abort
  call gina#core#meta#set('args', a:args)

  if exists('b:gina_initialized')
    return
  endif
  let b:gina_initialized = 1

  setlocal nomodeline
  setlocal buftype=nowrite
  setlocal noswapfile
  setlocal nomodifiable
  if a:args.params.partial
    setlocal bufhidden=wipe
  else
    setlocal bufhidden&
  endif

  augroup gina_command_diff_internal
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
    autocmd BufWinEnter <buffer> setlocal buflisted
    autocmd BufWinLeave <buffer> setlocal nobuflisted
  augroup END
endfunction

function! s:BufReadCmd() abort
  let git = gina#core#get_or_fail()
  let args = gina#core#meta#get_or_fail('args')
  let pipe = gina#process#pipe#stream()
  let pipe.writer = gina#core#writer#new(extend(
        \ gina#process#pipe#stream_writer(),
        \ s:writer
        \))
  call gina#core#buffer#assign_cmdarg()
  call gina#process#open(git, args, pipe)
  setlocal filetype=diff
endfunction


" Writer ---------------------------------------------------------------------
let s:writer = gina#util#inherit(gina#process#pipe#stream_writer())

function! s:writer.on_stop() abort
  call self.super(s:writer, 'on_stop')
  call gina#core#emitter#emit('command:called', s:SCHEME)
endfunction
