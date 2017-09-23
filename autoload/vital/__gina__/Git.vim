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

" The search paths are documented at
" https://git-scm.com/docs/git-rev-parse
function! s:ref(git, refname) abort
  let refname = a:refname ==# '@' ? 'HEAD' : a:refname
  let candidates = [
        \ refname,
        \ printf('refs/%s', refname),
        \ printf('refs/tags/%s', refname),
        \ printf('refs/heads/%s', refname),
        \ printf('refs/remotes/%s', refname),
        \ printf('refs/remotes/%s/HEAD', refname),
        \]
  let path = s:resolve(a:git, 'packed-refs')
  if !filereadable(path)
    let packed_refs = []
  else
    let packed_refs = map(
          \ filter(readfile(path), 'v:val[:0] !=# ''#'''),
          \ 'split(v:val)'
          \)
  endif
  for candidate in candidates
    let ref = s:_get_reference(a:git, candidate, packed_refs)
    if !empty(ref)
      return ref
    endif
  endfor
  return {}
endfunction


" Private --------------------------------------------------------------------
function! s:_get_reference(git, refname, packed_refs) abort
  let ref = s:_get_reference_trad(a:git, a:refname, a:packed_refs)
  if !empty(ref)
    return ref
  endif
  return s:_get_reference_packed(a:git, a:refname, a:packed_refs)
endfunction

function! s:_get_reference_trad(git, refname, packed_refs) abort
  let path = s:resolve(a:git, a:refname)
  if !filereadable(path)
    return {}
  endif
  let content = get(readfile(path), 0, '')
  if content =~# '^ref:'
    return s:_get_reference(
          \ a:git,
          \ matchstr(content, '^ref:\s\+\zs.\+'),
          \ a:packed_refs,
          \)
  endif
  let name = matchstr(a:refname, '^refs/\%(heads\|remotes\|tags\)/\zs.*')
  return {
        \ 'name': empty(name) ? content[:7] : name,
        \ 'path': a:refname,
        \ 'hash': content,
        \}
endfunction

function! s:_get_reference_packed(git, refname, packed_refs) abort
  let record = get(filter(copy(a:packed_refs), 'v:val[1] ==# a:refname'), 0, '')
  if empty(record)
    return {}
  endif
  let refname = record[1]
  let name = matchstr(refname, '^refs/\%(heads\|remotes\|tags\)/\zs.*')
  return {
        \ 'name': name,
        \ 'path': refname,
        \ 'hash': record[0],
        \}
endfunction
