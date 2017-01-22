function! s:_vital_loaded(V) abort
  let s:INI = a:V.import('Text.INI')
  let s:Path = a:V.import('System.Filepath')
  let s:String = a:V.import('Data.String')
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Text.INI',
        \ 'System.Filepath',
        \ 'Data.String',
        \]
endfunction

function! s:new(path) abort
  let path = s:Path.remove_last_separator(expand(a:path))
  let dirpath = isdirectory(path) ? path : fnamemodify(path, ':p:h')
  let dirpath = simplify(s:Path.abspath(s:Path.realpath(path)))

  " Find worktree
  let dgit = finddir('.git', fnameescape(dirpath) . ';')
  let dgit = empty(dgit) ? '' : fnamemodify(dgit, ':p:h')
  let fgit = findfile('.git', fnameescape(dirpath) . ';')
  let fgit = empty(fgit) ? '' : fnamemodify(fgit, ':p')
  let worktree = len(dgit) > len(fgit) ? dgit : fgit
  let worktree = empty(worktree) ? '' : fnamemodify(worktree, ':h')
  if empty(worktree)
    return {}
  endif

  " Find repository
  let repository = s:Path.join(worktree, '.git')
  if filereadable(repository)
    " A '.git' may be a file which was created by '--separate-git-dir' option
    let lines = readfile(repository)
    if empty(lines)
      throw printf(
            \ 'vital: Git: An invalid .git file has found at "%s".',
            \ repository,
            \)
    endif
    let gitdir = matchstr(lines[0], '^gitdir:\s*\zs.\+$')
    let is_abs = s:Path.is_absolute(gitdir)
    let repository = is_abs ? gitdir : repository[:-5] . gitdir
    let repository = empty(repository) ? '' : fnamemodify(repository, ':p:h')
  endif

  " Find commondir
  let commondir = ''
  if filereadable(s:Path.join(repository, 'commondir'))
    let commondir = readfile(s:Path.join(repository, 'commondir'))[0]
    let commondir = s:Path.join(repository, commondir)
  endif

  let git = {
        \ 'worktree': simplify(s:Path.realpath(worktree)),
        \ 'repository': simplify(s:Path.realpath(repository)),
        \ 'commondir': simplify(s:Path.realpath(commondir)),
        \}
  lockvar git.worktree
  lockvar git.repository
  lockvar git.commondir
  return git
endfunction

function! s:abspath(git, path) abort
  let relpath = s:Path.realpath(expand(a:path))
  if s:Path.is_absolute(relpath)
    return relpath
  endif
  return s:Path.join(a:git.worktree, relpath)
endfunction

function! s:relpath(git, path) abort
  let abspath = s:Path.realpath(expand(a:path))
  if s:Path.is_relative(abspath)
    return abspath
  endif
  let pattern = s:String.escape_pattern(a:git.worktree . s:Path.separator())
  return abspath =~# '^' . pattern
        \ ? matchstr(abspath, '^' . pattern . '\zs.*')
        \ : abspath
endfunction

function! s:resolve(git, path) abort
  let path = s:Path.realpath(a:path)
  let path1 = s:Path.join(a:git.repository, path)
  let path2 = empty(a:git.commondir)
        \ ? ''
        \ : s:Path.join(a:git.commondir, path)
  return filereadable(path1) || isdirectory(path1)
        \ ? path1
        \ : filereadable(path2) || isdirectory(path2)
        \   ? path2
        \   : path1
endfunction

function! s:get_config(git, ...) abort
  let path = s:resolve(a:git, 'config')
  return call(s:INI.parse_file, [path] + a:000, s:INI)
endfunction

function! s:get_remote_of(git, remote, ...) abort
  let config = a:0 > 0 ? a:1 : s:get_config(a:git)
  return get(config, printf('remote "%s"', a:remote), {})
endfunction

function! s:get_branch_of(git, branch, ...) abort
  let config = a:0 > 0 ? a:1 : s:get_config(a:git)
  let branch = s:_resolve_branch(a:git, a:branch)
  return get(config, printf('branch "%s"', branch), {})
endfunction

function! s:get_hashref_of(git, ref) abort
  let ref = s:_normalize_ref(a:git, a:ref)
  let path = s:resolve(a:git, ref)
  if !filereadable(path)
    return a:ref
  endif
  let content = get(readfile(path), 0, '')
  if empty(content)
    " ref is missing in traditional directory, the ref should be written in
    " packed-ref then
    let filter_code = printf(
          \ 'v:val[0] !=# "#" && v:val[-%d:] ==# ref',
          \ len(ref)
          \)
    let packed_refs = filter(
          \ readfile(s:resolve(a:git, 'packed-refs')),
          \ filter_code
          \)
    let content = get(split(get(packed_refs, 0, '')), 0, '')
  endif
  return content
endfunction


" Private --------------------------------------------------------------------
function! s:_normalize_ref(git, ref) abort
  if a:ref =~# '^refs/'
    return a:ref
  endif
  let path = s:resolve(a:git, a:ref)
  if !filereadable(path)
    return a:ref
  endif
  let content = get(readfile(s:resolve(a:git, a:ref)), 0, '')
  return matchstr(content, '^ref: \zs.\+')
endfunction

function! s:_resolve_ref(git, ref) abort
  let path = s:resolve(a:git, a:ref)
  if !filereadable(path)
    return a:ref
  endif
  let content = get(readfile(path), 0, '')
  let ref = matchstr(content, '^ref: \zs.\+')
  return empty(ref) ? a:ref : s:_resolve_ref(a:git, ref)
endfunction

function! s:_resolve_branch(git, branch) abort
  if a:branch ==# 'HEAD'
    let ref = s:_resolve_ref(a:git, 'HEAD')
  else
    let ref = s:_resolve_ref(a:git, 'refs/heads/' . a:branch)
  endif
  return matchstr(ref, '^refs/heads/\zs.*')
endfunction
