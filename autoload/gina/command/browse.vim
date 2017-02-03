let s:Config = vital#gina#import('Config')
let s:Formatter = vital#gina#import('Data.String.Formatter')
let s:Git = vital#gina#import('Git')
let s:Path = vital#gina#import('System.Filepath')

let s:FORMAT_MAP = {
      \ 'pt': 'path',
      \ 'ls': 'line_start',
      \ 'le': 'line_end',
      \ 'c0': 'commit0',
      \ 'c1': 'commit1',
      \ 'c2': 'commit2',
      \ 'h0': 'hash0',
      \ 'h1': 'hash1',
      \ 'h2': 'hash2',
      \ 'r0': 'revision0',
      \ 'r1': 'revision1',
      \ 'r2': 'revision2',
      \}


function! gina#command#browse#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args, a:range)

  let revinfo = s:parse_revision(git, args.params.revision)
  let base_url = s:build_base_url(
        \ s:get_remote_url(git, revinfo.commit1, revinfo.commit2),
        \ args.params.scheme is# v:null
        \   ? empty(args.params.path) ? 'root' : '_'
        \   : args.params.scheme,
        \)
  let url = s:Formatter.format(base_url, s:FORMAT_MAP, {
        \ 'path': s:Path.unixpath(gina#core#repo#relpath(git, args.params.path)),
        \ 'line_start': get(args.params.range, 0, ''),
        \ 'line_end': get(args.params.range, 1, ''),
        \ 'commit0': revinfo.commit0,
        \ 'commit1': revinfo.commit1,
        \ 'commit2': revinfo.commit2,
        \ 'hash0': revinfo.hash0,
        \ 'hash1': revinfo.hash1,
        \ 'hash2': revinfo.hash2,
        \ 'revision0': args.params.exact ? revinfo.hash0 : revinfo.commit0,
        \ 'revision1': args.params.exact ? revinfo.hash1 : revinfo.commit1,
        \ 'revision2': args.params.exact ? revinfo.hash2 : revinfo.commit2,
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
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args, range) abort
  let args = gina#command#parse_args(a:args)
  let args.params = {}
  let args.params.yank = args.pop('--yank')
  let args.params.exact = args.pop('--exact')
  let args.params.range = a:range == [1, line('$')] ? [] : a:range
  let args.params.scheme = args.pop('--scheme', v:null)
  let args.params.revision = args.pop(1, get(gina#core#buffer#params('%'), 'revision', ''))
  let args.params.path = gina#core#repo#expand(get(args.residual(), 0, '%'))
  return args.lock()
endfunction

function! s:parse_revision(git, revision) abort
  if a:revision =~# '^.\{-}\.\.\..*$'
    let [commit1, commit2] = gina#core#commit#split(a:git, a:revision)
    let commit1 = empty(commit1) ? 'HEAD' : commit1
    let commit2 = empty(commit2) ? 'HEAD' : commit2
  elseif a:revision =~# '^.\{-}\.\..*$'
    let [commit1, commit2] = gina#core#commit#split(a:git, a:revision)
    let commit1 = empty(commit1) ? 'HEAD' : commit1
    let commit2 = empty(commit2) ? 'HEAD' : commit2
  else
    let commit1 = empty(a:revision) ? 'HEAD' : a:revision
    let commit2 = 'HEAD'
  endif
  let commit0 = gina#core#commit#resolve(a:git, a:revision)
  let commit0 = empty(commit0) ? 'HEAD' : commit0

  let ref0 = s:Git.ref(a:git, commit0)
  let ref1 = s:Git.ref(a:git, commit1)
  let ref2 = s:Git.ref(a:git, commit2)
  return {
        \ 'commit0': empty(ref0) ? commit0 : ref0.name,
        \ 'commit1': empty(ref1) ? commit1 : ref1.name,
        \ 'commit2': empty(ref2) ? commit2 : ref2.name,
        \ 'hash0': empty(ref0) ? commit0 : ref0.hash,
        \ 'hash1': empty(ref1) ? commit1 : ref1.hash,
        \ 'hash2': empty(ref2) ? commit2 : ref2.hash,
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


call s:Config.define('gina#command#browse', {
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
