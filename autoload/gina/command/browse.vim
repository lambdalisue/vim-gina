let s:Config = vital#gina#import('Config')
let s:Exception = vital#gina#import('Vim.Exception')
let s:Formatter = vital#gina#import('Data.String.Formatter')
let s:Git = vital#gina#import('Git')
let s:Path = vital#gina#import('System.Filepath')


function! gina#command#browse#define() abort
  return s:command
endfunction


" Instance -------------------------------------------------------------------
let s:command = {}

function! s:command.command(range, qargs, qmods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:qargs, a:range)
  let url = s:build_url(git, args)
  if args.params.yank
    call gina#util#yank(url)
  else
    call gina#util#open(url)
  endif
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, qargs, range) abort
  let args = gina#command#parse(a:qargs)
  let args.params = {}
  let args.params.yank = args.pop('--yank')
  let args.params.exact = args.pop('--exact')
  let args.params.remote = args.pop('--remote', '')
  let args.params.selection = a:range == [1, line('$')] ? [] : a:range
  let args.params.commit = args.pop(
        \ 1,
        \ get(gina#util#params('%'), 'commit', '')
        \)
  let args.params.path = s:Path.unixpath(gina#util#relpath(
        \ gina#util#expand(get(args.residual(), 0, '%'))
        \))
  let args.params.scheme = args.pop(
        \ '--scheme',
        \ empty(args.params.path) ? 'root' : '_'
        \)

  let config = s:Git.get_config(a:git)
  let args.params = s:assign_commit(a:git, config, args.params)
  let args.params = s:assign_remote(a:git, config, args.params)
  return args.lock()
endfunction

function! s:assign_commit(git, config, params) abort
  let commit = a:params.commit
  if commit =~# '^.\{-}\.\.\..*$'
    let [commit1, commit2] = gina#util#commit#split(a:git, commit)
    let commit1 = empty(commit1) ? 'HEAD' : commit1
    let commit2 = empty(commit2) ? 'HEAD' : commit2
  elseif commit =~# '^.\{-}\.\..*$'
    let [commit1, commit2] = gina#util#commit#split(a:git, commit)
    let commit1 = empty(commit1) ? 'HEAD' : commit1
    let commit2 = empty(commit2) ? 'HEAD' : commit2
  else
    let commit1 = empty(commit) ? 'HEAD' : commit
    let commit2 = 'HEAD'
  endif
  let commit = gina#util#commit#resolve(a:git, commit)
  let commit = empty(commit) ? 'HEAD' : commit
  return extend(a:params, {
        \ 'commit': commit,
        \ 'commit1': commit1,
        \ 'commit2': commit2,
        \ 'hashref': s:Git.get_hashref_of(a:git, commit),
        \ 'hashref1': s:Git.get_hashref_of(a:git, commit1),
        \ 'hashref2': s:Git.get_hashref_of(a:git, commit2),
        \})
endfunction

function! s:assign_remote(git, config, params) abort
  if empty(a:params.remote)
    let branch = s:Git.get_branch_of(a:git, a:params.commit1, a:config)
    let branch = empty(branch) ? s:Git.get_branch_of(a:git, a:params.commit2, a:config) : branch
    let branch = empty(branch) ? s:Git.get_branch_of(a:git, 'HEAD', a:config) : branch
    let remote = get(branch, 'remote', 'origin')
  else
    let remote = a:params.remote
  endif
  return extend(a:params, {
        \ 'remote': remote,
        \ 'url': get(s:Git.get_remote_of(a:git, remote, a:config), 'url', ''),
        \})
endfunction

function! s:build_url(git, args) abort
  let params = a:args.params
  let line_start = get(params.selection, 0, '')
  let line_end = get(params.selection, 1, '')
  let revision = params.exact ? params.hashref : params.commit
  let revision1 = params.exact ? params.hashref1 : params.commit1
  let revision2 = params.exact ? params.hashref2 : params.commit2
  let url = s:format(params.scheme, params.url, {
        \ 'path': params.path,
        \ 'remote': params.remote,
        \ 'revision': revision,
        \ 'revision1': revision1,
        \ 'revision2': revision2,
        \ 'commit': params.commit,
        \ 'commit1': params.commit1,
        \ 'commit2': params.commit2,
        \ 'hashref': params.hashref,
        \ 'hashref1': params.hashref1,
        \ 'hashref2': params.hashref2,
        \ 'line_start': line_start,
        \ 'line_end': line_end,
        \})
  if !empty(url)
    return url
  endif
  throw s:Exception.warn(printf(
        \ 'No url translation pattern for "%s:%s" (%s) is found.',
        \ params.remote,
        \ params.commit,
        \ params.url,
        \))
endfunction

function! s:format(scheme, remote_url, params) abort
  let format_map = {
        \ 'pt': 'path',
        \ 'rm': 'remote',
        \ 'r0': 'revision',
        \ 'r1': 'revision1',
        \ 'r2': 'revision2',
        \ 'c0': 'commit',
        \ 'c1': 'commit1',
        \ 'c2': 'commit2',
        \ 'h0': 'hashref',
        \ 'h1': 'hashref1',
        \ 'h2': 'hashref2',
        \ 'ls': 'line_start',
        \ 'le': 'line_end',
        \}
  let patterns = g:gina#command#browse#translation_patterns
  let patterns = extend(
        \ deepcopy(patterns),
        \ g:gina#command#browse#extra_translation_patterns
        \)
  let baseurl = s:build_baseurl(a:scheme, a:remote_url, patterns)
  if empty(baseurl)
    return ''
  endif
  return s:Formatter.format(baseurl, format_map, a:params)
endfunction

function! s:build_baseurl(scheme, remote_url, translation_patterns) abort
  for [domain, info] in items(a:translation_patterns)
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
      \       '_':     'https://\1/\2/\3/blob/%r0/%pt%{#L|}ls%{-L|}le',
      \       'root':  'https://\1/\2/\3/tree/%r0/',
      \       'blame': 'https://\1/\2/\3/blame/%r0/%pt%{#L|}ls%{-L|}le',
      \       'compare': 'https://\1/\2/\3/compare/%r1...%r2',
      \     },
      \   ],
      \   'bitbucket.org': [
      \     [
      \       '\vhttps?://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit\@(%domain):(.{-})/(.{-})%(\.git)?$',
      \       '\vssh://git\@(%domain)/(.{-})/(.{-})%(\.git)?$',
      \     ], {
      \       '_':     'https://\1/\2/\3/src/%r0/%pt%{#cl-|}ls',
      \       'root':  'https://\1/\2/\3/branch/%r0/',
      \       'blame': 'https://\1/\2/\3/annotate/%r0/%pt',
      \       'compare':  'https://\1/\2/\3/diff/%pt?diff1=%h1&diff2=%h2',
      \     },
      \   ],
      \ },
      \ 'extra_translation_patterns': {},
      \})
