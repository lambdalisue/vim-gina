let s:Emitter = vital#gina#import('Emitter')
let s:Exception = vital#gina#import('Vim.Exception')
let s:Group = vital#gina#import('Vim.Buffer.Group')
let s:String = vital#gina#import('Data.String')

let s:is_windows = has('win32') || has('win64')
let s:WORKTREE = '@@'


function! gina#command#patch#define() abort
  return s:command
endfunction


" Instance -------------------------------------------------------------------
let s:command = {}

function! s:command.command(range, qargs, qmods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:qargs)
  let group = s:Group.new()

  silent diffoff!

  let opener1 = args.params.opener
  let opener2 = empty(matchstr(&diffopt, 'vertical'))
        \ ? 'split'
        \ : 'vsplit'

  call s:open(0, a:qargs, opener1, 'HEAD', args.params)
  call gina#util#diffthis()
  call group.add()
  let bufnr1 = bufnr('%')

  call s:open(1, a:qargs, opener2, '', args.params)
  call gina#util#diffthis()
  call group.add()
  let bufnr2 = bufnr('%')

  call s:open(2, a:qargs, opener2, s:WORKTREE, args.params)
  call gina#util#diffthis()
  call group.add({'keep': 1})
  let bufnr3 = bufnr('%')

  " WORKTREE
  execute printf(
        \ 'nnoremap <silent><buffer> <Plug>(gina-diffput) :diffput %d<CR>',
        \ bufnr2,
        \)
  execute printf(
        \ 'nnoremap <silent><buffer> <Plug>(gina-diffget) :diffget %d<CR>',
        \ bufnr2,
        \)
  nmap dp <Plug>(gina-diffput)
  nmap do <Plug>(gina-diffget)

  " HEAD
  execute printf('%dwincmd w', bufwinnr(bufnr1))
  execute printf(
        \ 'nnoremap <silent><buffer> <Plug>(gina-diffput) :diffput %d<CR>',
        \ bufnr2,
        \)
  nmap dp <Plug>(gina-diffput)

  " INDEX
  execute printf('%dwincmd w', bufwinnr(bufnr2))
  execute printf(
        \ 'nnoremap <silent><buffer> <Plug>(gina-diffput) :diffput %d<CR>',
        \ bufnr3,
        \)
  execute printf(
        \ 'nnoremap <silent><buffer> <Plug>(gina-diffget-l) :diffget %d<CR>',
        \ bufnr1,
        \)
  execute printf(
        \ 'nnoremap <silent><buffer> <Plug>(gina-diffget-r) :diffget %d<CR>',
        \ bufnr3,
        \)
  nmap dp <Plug>(gina-diffput)
  nmap dol <Plug>(gina-diffget-l)
  nmap dor <Plug>(gina-diffget-r)

  setlocal buftype=acwrite
  setlocal modifiable
  augroup gina_internal_command
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> call s:BufWriteCmd()
  augroup END

  " Update diff
  call gina#util#diffupdate()
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, qargs) abort
  let args = gina#command#args(a:qargs)
  let args.params = {}
  let args.params.async = args.pop('--async')
  let args.params.groups = [
        \ args.pop('--group1', 'patch-l'),
        \ args.pop('--group2', 'patch-c'),
        \ args.pop('--group3', 'patch-r'),
        \]
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.cmdarg = join([
        \ args.pop('^++enc'),
        \ args.pop('^++ff'),
        \])
  let args.params.line = args.pop('--line', v:null)
  let args.params.col = args.pop('--col', v:null)
  let args.params.path = gina#util#relpath(
        \ gina#util#expand(get(args.residual(), 0, '%'))
        \)
  return args.lock()
endfunction

function! s:open(n, qmods, opener, commit, params) abort
  if a:commit ==# s:WORKTREE
    execute printf(
          \ '%s Gina %s edit %s %s %s %s %s -- %s',
          \ a:qmods,
          \ a:params.async ? '--async' : '',
          \ a:params.cmdarg,
          \ gina#util#shellescape(a:opener, '--opener='),
          \ gina#util#shellescape(a:params.groups[a:n], '--group='),
          \ gina#util#shellescape(a:params.line, '--line='),
          \ gina#util#shellescape(a:params.col, '--col='),
          \ gina#util#fnameescape(a:params.path),
          \)
  else
    execute printf(
          \ '%s Gina %s show %s %s %s %s %s %s %s -- %s',
          \ a:qmods,
          \ a:params.async ? '--async' : '',
          \ a:params.cmdarg,
          \ gina#util#shellescape(a:opener, '--opener='),
          \ gina#util#shellescape(a:params.groups[a:n], '--group='),
          \ gina#util#shellescape(a:params.line, '--line='),
          \ gina#util#shellescape(a:params.col, '--col='),
          \ gina#util#shellescape(a:commit),
          \ gina#util#fnameescape(a:params.path),
          \)
  endif
endfunction

function! s:patch(git) abort
  let path = gina#util#expand('%')
  call gina#process#call(a:git, [
        \ 'add',
        \ '--intent-to-add',
        \ '--',
        \ gina#util#abspath(path),
        \])
  let diff = s:diff(a:git, path, getline(1, '$'))
  let result = s:apply(a:git, diff)
  return result
endfunction

function! s:diff(git, path, buffer) abort
  let tempfile = tempname()
  let tempfile1 = tempfile . '.index'
  let tempfile2 = tempfile . '.buffer'
  try
    if writefile(s:index(a:git, a:path), tempfile1) == -1
      return
    endif
    if writefile(a:buffer, tempfile2) == -1
      return
    endif
    " NOTE:
    " --no-index force --exit-code option.
    " --exit-code mean that the program exits with 1 if there were differences
    " and 0 means no differences
    let result = gina#process#call(a:git, [
          \ 'diff',
          \ '--no-index',
          \ '--unified=1',
          \ '--',
          \ tempfile1,
          \ tempfile2,
          \])
    if !result.status
      throw s:Exception.info(
            \ 'No difference between index and buffer'
            \)
    endif
    return s:replace_filenames_in_diff(
          \ result.content,
          \ tempfile1,
          \ tempfile2,
          \ a:path,
          \)
  finally
    silent! call delete(tempfile1)
    silent! call delete(tempfile2)
  endtry
endfunction

function! s:index(git, path) abort
  let result = gina#process#call(a:git, ['show', ':' . a:path])
  if result.status
    return []
  endif
  return result.content
endfunction

function! s:replace_filenames_in_diff(content, filename1, filename2, repl) abort
  " replace tempfile1/tempfile2 in the header to a:filename
  "
  "   diff --git a/<tempfile1> b/<tempfile2>
  "   index XXXXXXX..XXXXXXX XXXXXX
  "   --- a/<tempfile1>
  "   +++ b/<tempfile2>
  "
  let src1 = s:String.escape_pattern(a:filename1)
  let src2 = s:String.escape_pattern(a:filename2)
  if s:is_windows
    " NOTE:
    " '\' in {content} from 'git diff' are escaped so double escape is required
    " to substitute such path
    " NOTE:
    " escape(src1, '\') cannot be used while other characters such as '.' are
    " already escaped as well
    let src1 = substitute(src1, '\\\\', '\\\\\\\\', 'g')
    let src2 = substitute(src2, '\\\\', '\\\\\\\\', 'g')
  endif
  let repl = (a:filename1 =~# '^/' ? '/' : '') . a:repl
  let content = copy(a:content)
  let content[0] = substitute(content[0], src1, repl, '')
  let content[0] = substitute(content[0], src2, repl, '')
  let content[2] = substitute(content[2], src1, repl, '')
  let content[3] = substitute(content[3], src2, repl, '')
  return content
endfunction

function! s:apply(git, content) abort
  let tempfile = tempname()
  try
    if writefile(a:content, tempfile) == -1
      return
    endif
    let result = gina#process#call(a:git, [
          \ 'apply',
          \ '--verbose',
          \ '--cached',
          \ '--',
          \ tempfile,
          \])
    return result
  finally
    silent! call delete(tempfile)
  endtry
endfunction

function! s:BufWriteCmd() abort
  let git = gina#core#get_or_fail()
  let result = s:Exception.call(function('s:patch'), [git])
  if !empty(result)
    call gina#process#inform(result)
    call timer_start(100, function('s:emit'))
    setlocal nomodified
  endif
endfunction

function! s:emit(...) abort
  call s:Emitter.emit('gina:modified')
endfunction
