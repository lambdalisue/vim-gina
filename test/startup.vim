if exists('g:loaded_startup')
  finish
endif
let g:loaded_startup = 1

let s:Path = vital#gina#import('System.Filepath')

function! s:gte(lhs, rhs) abort
  if a:lhs ==# a:rhs
    return 1
  endif
  let lhs = map(split(a:lhs, '\.'), 'str2nr(v:val)')
  let rhs = map(split(a:rhs, '\.'), 'str2nr(v:val)')
  let size = min([len(lhs), len(rhs)])
  for i in range(size)
    if lhs[i] == rhs[i]
      continue
    endif
    return lhs[i] > rhs[i] ? 1 : 0
  endfor
  return 0
endfunction


" Git version check ----------------------------------------------------------
let g:git_version = matchstr(system('git --version'), '\%(\d\+\.\)\+\d')
let g:git_supported = {
      \ 'worktree': s:gte(g:git_version, '2.5.0'),
      \}

call themis#log('')
call themis#log('Git: ' . g:git_version)
call themis#log('  Support worktree: ' . g:git_supported.worktree)


" Simple git command executor ------------------------------------------------
let s:git = {}
function! s:git.execute(...) abort
  let command = a:0 == 1 ? a:1 : call('printf', a:000)
  let args = [
        \ 'git',
        \ '-c color.ui=false',
        \ '-c core.editor=false',
        \ '--no-pager',
        \]
  if !empty(get(self, 'worktree'))
    let args += ['-C', fnameescape(self.worktree)]
  endif
  return system(join(args + [command]))
endfunction


" Global themis events -------------------------------------------------------
let s:events = {}
function! s:events.initialize() abort
  let Path = vital#gina#import('System.Filepath')
  let root = resolve(tempname())
  let inside = Path.join(root, 'inside')
  let outside = Path.join(root, 'outside')
  let worktree = Path.join(root, 'worktree')
  let external = Path.join(root, 'external')

  " Construct the directory
  for path in [inside, outside, external]
    call mkdir(Path.join(path, 'A', 'foo'), 'p')
    call mkdir(Path.join(path, 'B', 'foo'), 'p')
    call mkdir(Path.join(path, 'C', 'foo'), 'p')
    call writefile(['A'], Path.join(path, 'A', 'foo', 'bar.txt'))
    call writefile(['B'], Path.join(path, 'B', 'foo', 'bar.txt'))
    call writefile(['C'], Path.join(path, 'C', 'foo', 'bar.txt'))
  endfor

  " Initialize directories as a git repository
  let git = copy(s:git)
  let git.worktree = inside
  call git.execute('init')
  call git.execute('add %s', fnameescape(Path.realpath('A/foo/bar.txt')))
  call git.execute('commit --quiet -m "First"')
  call git.execute('checkout --track -b develop')
  call git.execute('add %s', fnameescape(Path.realpath('B/foo/bar.txt')))
  call git.execute('commit --quiet -m "Second"')
  call git.execute('checkout master')
  call git.execute('add %s', fnameescape(Path.realpath('C/foo/bar.txt')))
  call git.execute('commit --quiet -m "Third"')

  if g:git_supported.worktree
    call git.execute('worktree add %s develop', fnameescape(worktree))
  endif

  let git.worktree = external
  call git.execute('init')
  call git.execute('add %s', fnameescape(Path.realpath('A/foo/bar.txt')))
  call git.execute('commit --quiet -m "Fourth"')

  let git.worktree = inside
  call git.execute('remote add external %s', fnameescape(external))
  call git.execute('fetch external')
  call git.execute('checkout --track -b external/master remotes/external/master')
  call git.execute('checkout master')

  let g:git_tester = {
        \ 'root': root,
        \ 'inside': inside,
        \ 'outside': outside,
        \ 'worktree': worktree,
        \ 'external': external,
        \}
  function! g:git_tester.attach(namespace) abort
    let Path = vital#gina#import('System.Filepath')
    for name in ['inside', 'outside', 'worktree', 'external']
      let a:namespace[name] = self[name]
      let a:namespace['f_' . name . '1'] = Path.join(self[name], 'A', 'foo', 'bar.txt')
      let a:namespace['f_' . name . '2'] = Path.join(self[name], 'B', 'foo', 'bar.txt')
      let a:namespace['f_' . name . '3'] = Path.join(self[name], 'C', 'foo', 'bar.txt')
      let a:namespace['d_' . name . '1'] = Path.join(self[name], 'A', 'foo')
      let a:namespace['d_' . name . '2'] = Path.join(self[name], 'B', 'foo')
      let a:namespace['d_' . name . '3'] = Path.join(self[name], 'C', 'foo')
    endfor
  endfunction

  " Log informations
  let git = copy(s:git)
  let git.worktree = inside
  call themis#log('Root: ' . root)
  call themis#log('Branches:')
  call themis#log(git.execute('branch -av'))
  call themis#log('***********************************************************')
endfunction

function! s:events.before_each() abort
  let g:gina#test#cwd = getcwd()
  windo bwipeout!
endfunction

function! s:events.after_each() abort
  silent execute printf('cd %s', fnameescape(g:gina#test#cwd))
endfunction


" Until: https://github.com/thinca/vim-themis/pull/42
execute printf(
      \ 'set runtimepath^=%s',
      \ fnameescape(s:Path.join(expand('<sfile>:h'), '.vendor'))
      \)
call themis#helper('global').with(s:events)
