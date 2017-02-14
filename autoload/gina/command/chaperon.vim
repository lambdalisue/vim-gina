let s:Group = vital#gina#import('Vim.Buffer.Group')
let s:String = vital#gina#import('Data.String')

let s:WORKTREE = '@@'
let s:REGION_PATTERN = printf("%s.\{-}%s\n",
      \ printf('%s[^\n]\{-}\%%(\n\|$\)', repeat('<', 7)),
      \ printf('%s[^\n]\{-}\%%(\n\|$\)', repeat('>', 7))
      \)


function! gina#command#chaperon#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let group = s:Group.new()

  silent diffoff!

  let opener1 = args.params.opener
  let opener2 = empty(matchstr(&diffopt, 'vertical'))
        \ ? 'split'
        \ : 'vsplit'

  call s:open(0, a:mods, opener1, ':2', args.params)
  call gina#util#diffthis()
  call group.add()
  let bufnr1 = bufnr('%')

  call s:open(1, a:mods, opener2, s:WORKTREE, args.params)
  call gina#util#diffthis()
  call group.add({'keep': 1})
  let bufnr2 = bufnr('%')

  call s:open(2, a:mods, opener2, ':3', args.params)
  call gina#util#diffthis()
  call group.add()
  let bufnr3 = bufnr('%')

  " Theirs (REMOTE)
  execute printf(
        \ 'nnoremap <silent><buffer> <Plug>(gina-diffput) :diffput %d<CR>',
        \ bufnr2,
        \)
  nmap dp <Plug>(gina-diffput)

  " Ours (Local)
  execute printf('%dwincmd w', bufwinnr(bufnr1))
  execute printf(
        \ 'nnoremap <silent><buffer> <Plug>(gina-diffput) :diffput %d<CR>',
        \ bufnr2,
        \)
  nmap dp <Plug>(gina-diffput)

  " WORKTREE
  execute printf('%dwincmd w', bufwinnr(bufnr2))
  execute printf(
        \ 'nnoremap <silent><buffer> <Plug>(gina-diffget-l) :diffget %d<CR>',
        \ bufnr1,
        \)
  execute printf(
        \ 'nnoremap <silent><buffer> <Plug>(gina-diffget-r) :diffget %d<CR>',
        \ bufnr3,
        \)
  nmap dol <Plug>(gina-diffget-l)
  nmap dor <Plug>(gina-diffget-r)
  let content = s:strip_conflict(getline(1, '$'))
  silent lockmarks keepjumps $delete _
  call setline(1, content)

  " Update diff
  call gina#util#diffupdate()
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = gina#command#parse_args(a:args)
  let args.params.groups = [
        \ args.pop('--group1', 'chaperon-l'),
        \ args.pop('--group2', 'chaperon-c'),
        \ args.pop('--group3', 'chaperon-r'),
        \]
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.line = args.pop('--line', v:null)
  let args.params.col = args.pop('--col', v:null)
  let args.params.abspath = gina#core#path#abspath(get(args.residual(), 0, '%'))
  return args.lock()
endfunction

function! s:open(n, mods, opener, commit, params) abort
  if a:commit ==# s:WORKTREE
    execute printf(
          \ '%s Gina %s edit %s %s %s %s %s -- %s',
          \ a:mods,
          \ a:params.async ? '--async' : '',
          \ a:params.cmdarg,
          \ gina#util#fnameescape(a:opener, '--opener='),
          \ gina#util#fnameescape(a:params.groups[a:n], '--group='),
          \ gina#util#fnameescape(a:params.line, '--line='),
          \ gina#util#fnameescape(a:params.col, '--col='),
          \ gina#util#fnameescape(a:params.abspath),
          \)
  else
    execute printf(
          \ '%s Gina %s show %s %s %s %s %s %s -- %s',
          \ a:mods,
          \ a:params.async ? '--async' : '',
          \ a:params.cmdarg,
          \ gina#util#fnameescape(a:opener, '--opener='),
          \ gina#util#fnameescape(a:params.groups[a:n], '--group='),
          \ gina#util#fnameescape(a:params.line, '--line='),
          \ gina#util#fnameescape(a:params.col, '--col='),
          \ gina#util#fnameescape(a:commit),
          \ gina#util#fnameescape(a:params.abspath),
          \)
  endif
endfunction


function! s:get_newline() abort
  let ff = &fileformat
  return ff ==# 'unix' ? "\n" : ff ==# 'dos' ? "\r\n" : "\r"
endfunction

function! s:strip_conflict(content) abort
  let newline = s:get_newline()
  let text = s:String.join_posix_lines(a:content, newline)
  let text = substitute(text, s:REGION_PATTERN, '', 'g')
  return s:String.split_posix_text(text, newline)
endfunction
