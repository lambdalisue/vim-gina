let s:Formatter = vital#gina#import('Data.String.Formatter')
let s:Git = vital#gina#import('Git')
let s:Path = vital#gina#import('System.Filepath')
let s:SCHEME = gina#command#scheme(expand('<sfile>'))

let s:FORMAT_MAP = {
      \ 'pt': 'relpath',
      \ 'ls': 'line_start',
      \ 'le': 'line_end',
      \ 'c0': 'commit0',
      \ 'c1': 'commit1',
      \ 'c2': 'commit2',
      \ 'h0': 'hash0',
      \ 'h1': 'hash1',
      \ 'h2': 'hash2',
      \ 'r0': 'rev0',
      \ 'r1': 'rev1',
      \ 'r2': 'rev2',
      \}


function! gina#command#browse#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args, a:range)

  let revinfo = s:parse_rev(git, args.params.rev)
  let base_url = s:build_base_url(
        \ s:get_remote_url(git, revinfo.commit1, revinfo.commit2),
        \ args.params.scheme is# v:null
        \   ? empty(args.params.abspath) ? 'root' : '_'
        \   : args.params.scheme,
        \)
  let url = s:Formatter.format(base_url, s:FORMAT_MAP, {
        \ 'relpath': gina#core#repo#relpath(git, args.params.abspath),
        \ 'line_start': get(args.params.range, 0, ''),
        \ 'line_end': get(args.params.range, 1, ''),
        \ 'commit0': revinfo.commit0,
        \ 'commit1': revinfo.commit1,
        \ 'commit2': revinfo.commit2,
        \ 'hash0': revinfo.hash0,
        \ 'hash1': revinfo.hash1,
        \ 'hash2': revinfo.hash2,
        \ 'rev0': args.params.exact ? revinfo.hash0 : revinfo.commit0,
        \ 'rev1': args.params.exact ? revinfo.hash1 : revinfo.commit1,
        \ 'rev2': args.params.exact ? revinfo.hash2 : revinfo.commit2,
        \})
  if empty(url)
    throw gina#core#exception#warn(printf(
          \ 'No url translation pattern for "%s" is found.',
          \ args.params.rev,
          \))
  endif

  if args.params.yank
    call gina#util#yank(url)
  else
    call gina#util#open(url)
  endif
  call gina#core#emitter#emit('command:called', s:SCHEME)
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args, range) abort
  let args = a:args.clone()
  let args.params.yank = args.pop('--yank')
  let args.params.exact = args.pop('--exact')
  let args.params.range = a:range == [1, line('$')] ? [] : a:range
  let args.params.scheme = args.pop('--scheme', v:null)
  let args.params.abspath = gina#core#path#abspath(get(args.residual(), 0, '%'))
  let args.params.rev = args.pop(1, gina#core#buffer#param('%', 'rev', ''))
  return args.lock()
endfunction

function! s:parse_rev(git, rev) abort
  if a:rev =~# '^.\{-}\.\.\..*$'
    let [commit1, commit2] = gina#core#treeish#split_rev(a:git, a:rev)
    let commit1 = empty(commit1) ? 'HEAD' : commit1
    let commit2 = empty(commit2) ? 'HEAD' : commit2
  elseif a:rev =~# '^.\{-}\.\..*$'
    let [commit1, commit2] = gina#core#treeish#split_rev(a:git, a:rev)
    let commit1 = empty(commit1) ? 'HEAD' : commit1
    let commit2 = empty(commit2) ? 'HEAD' : commit2
  else
    let commit1 = empty(a:rev) ? 'HEAD' : a:rev
    let commit2 = 'HEAD'
  endif
  let commit0 = gina#core#treeish#resolve_rev(a:git, a:rev)
  let commit0 = empty(commit0) ? 'HEAD' : commit0

  let hash0 = gina#core#treeish#sha1(a:git, commit0)
  let hash1 = gina#core#treeish#sha1(a:git, commit1)
  let hash2 = gina#core#treeish#sha1(a:git, commit2)
  return {
        \ 'commit0': commit0,
        \ 'commit1': commit1,
        \ 'commit2': commit2,
        \ 'hash0': hash0,
        \ 'hash1': hash1,
        \ 'hash2': hash2,
        \}
endfunction

function! s:get_remote_url(git, commit1, commit2) abort
  let config = gina#core#repo#config(a:git)
  " Find a corresponding 'remote'
  let candidates = [a:commit1, a:commit2, 'HEAD']
  for candidate in candidates
    let remote = get(
          \ get(config, 'remote', {}),
          \ get(get(get(config, 'branch', {}), candidate, {}), 'remote', ''),
          \ {}
          \)
    if !empty(remote)
      break
    endif
  endfor
  " Use a 'remote' of 'origin' if no 'remote' is found
  let remote = empty(remote)
        \ ? get(get(config, 'remote', {}), 'origin', {})
        \ : remote
  return get(remote, 'url', '')
endfunction

function! s:build_base_url(remote_url, scheme) abort
  for [domain, info] in items(g:gina#command#browse#translation_patterns)
    for pattern in info[0]
      let pattern = substitute(pattern, '\C' . '%domain', domain, 'g')
      if a:remote_url =~# pattern
        let repl = get(info[1], a:scheme, a:remote_url)
        return substitute(a:remote_url, '\C' . pattern, repl, 'g')
      endif
    endfor
  endfor
  return ''
endfunction

call gina#config(expand('<sfile>'), {
      \ 'translation_patterns': {
      \   'github.com': [
      \     [
      \       '\vhttps?://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit\@(%domain):(.{-})/(.{-})%(\.git)?$',
      \       '\vssh://git\@(%domain)/(.{-})/(.{-})%(\.git)?$',
      \     ], {
      \       '_': 'https://\1/\2/\3/blob/%r0/%pt%{#L|}ls%{-L|}le',
      \       'root': 'https://\1/\2/\3/tree/%r0/',
      \       'blame': 'https://\1/\2/\3/blame/%r0/%pt%{#L|}ls%{-L|}le',
      \       'compare': 'https://\1/\2/\3/compare/%h1...%h2',
      \     },
      \   ],
      \   'bitbucket.org': [
      \     [
      \       '\vhttps?://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit\@(%domain):(.{-})/(.{-})%(\.git)?$',
      \       '\vssh://git\@(%domain)/(.{-})/(.{-})%(\.git)?$',
      \     ], {
      \       '_': 'https://\1/\2/\3/src/%r0/%pt%{#cl-|}ls',
      \       'root': 'https://\1/\2/\3/branch/%r0/',
      \       'blame': 'https://\1/\2/\3/annotate/%r0/%pt',
      \       'compare': 'https://\1/\2/\3/diff/%pt?diff1=%h1&diff2=%h2',
      \     },
      \   ],
      \ },
      \})
