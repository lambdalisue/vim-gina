let s:Group = vital#gina#import('Vim.Buffer.Group')
let s:String = vital#gina#import('Data.String')

let s:SCHEME = gina#command#scheme(expand('<sfile>'))
let s:WORKTREE = '@@'
let s:REGION_PATTERN = printf('%s.\{-}%s\r\?\n\?',
      \ printf('%s[^\n]\{-}\%%(\n\|$\)', repeat('<', 7)),
      \ printf('%s[^\n]\{-}\%%(\n\|$\)', repeat('>', 7))
      \)


function! gina#command#chaperon#call(range, args, mods) abort
  call gina#process#register(s:SCHEME, 1)
  try
    call s:call(a:range, a:args, a:mods)
  finally
    call gina#process#unregister(s:SCHEME, 1)
  endtry
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = a:args.clone()
  let args.params.groups = [
        \ args.pop('--group1', 'chaperon-l'),
        \ args.pop('--group2', 'chaperon-c'),
        \ args.pop('--group3', 'chaperon-r'),
        \]
  let args.params.opener = args.pop('--opener', 'edit')
  call gina#core#args#extend_path(a:git, args, args.pop(1))
  call gina#core#args#extend_line(a:git, args, args.pop('--line'))
  call gina#core#args#extend_col(a:git, args, args.pop('--col'))
  return args.lock()
endfunction

function! s:call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let mods = gina#util#contain_direction(a:mods)
        \ ? 'keepalt ' . a:mods
        \ : join(['keepalt', 'rightbelow', a:mods])
  let opener1 = args.params.opener
  let opener2 = empty(matchstr(&diffopt, 'vertical'))
        \ ? 'split'
        \ : 'vsplit'
  let group = s:Group.new()

  diffoff!
  call s:open(0, mods, opener1, ':2', args.params)
  let bufnr1 = bufnr('%')

  call s:open(1, mods, opener2, s:WORKTREE, args.params)
  let bufnr2 = bufnr('%')

  call s:open(2, mods, opener2, ':3', args.params)
  let bufnr3 = bufnr('%')

  " :3 Theirs (REMOTE)
  call gina#util#diffthis()
  call group.add()
  call s:define_plug_mapping('diffput', bufnr2)
  if g:gina#command#chaperon#use_default_mappings
    nmap dp <Plug>(gina-diffput)
  endif

  " :2 Ours (Local)
  execute printf('%dwincmd w', bufwinnr(bufnr1))
  call gina#util#diffthis()
  call group.add()
  call s:define_plug_mapping('diffput', bufnr2)
  if g:gina#command#chaperon#use_default_mappings
    nmap dp <Plug>(gina-diffput)
  endif

  " WORKTREE
  execute printf('%dwincmd w', bufwinnr(bufnr2))
  call gina#util#diffthis()
  call group.add({'keep': 1})
  call s:define_plug_mapping('diffget', bufnr1, '-l')
  call s:define_plug_mapping('diffget', bufnr3, '-r')
  if g:gina#command#chaperon#use_default_mappings
    nmap dol <Plug>(gina-diffget-l)
    nmap dor <Plug>(gina-diffget-r)
  endif

  if !&l:modified
    let content = s:strip_conflict(getline(1, '$'))
    silent keepjumps %delete _
    call setline(1, content)
    setlocal modified
  endif

  call gina#util#diffupdate()
  normal! zm
  call gina#core#emitter#emit('command:called', s:SCHEME)
endfunction

function! s:define_plug_mapping(command, bufnr, ...) abort
  let suffix = a:0 ? a:1 : ''
  let lhs = printf('<Plug>(gina-%s%s)', a:command, suffix)
  let rhs = printf(':<C-u>%s %d<CR>', a:command, a:bufnr)
  call gina#util#map(lhs, rhs, {
        \ 'mode': 'n',
        \ 'noremap': 1,
        \ 'silent': 1,
        \})
endfunction

function! s:open(n, mods, opener, commit, params) abort
  if a:commit ==# s:WORKTREE
    execute printf(
          \ '%s Gina edit %s %s %s %s %s %s',
          \ a:mods,
          \ a:params.cmdarg,
          \ gina#util#shellescape(a:opener, '--opener='),
          \ gina#util#shellescape(a:params.groups[a:n], '--group='),
          \ gina#util#shellescape(a:params.line, '--line='),
          \ gina#util#shellescape(a:params.col, '--col='),
          \ gina#util#shellescape(a:params.path),
          \)
  else
    let treeish = gina#core#treeish#build(a:commit, a:params.path)
    execute printf(
          \ '%s Gina show %s %s %s %s %s %s',
          \ a:mods,
          \ a:params.cmdarg,
          \ gina#util#shellescape(a:opener, '--opener='),
          \ gina#util#shellescape(a:params.groups[a:n], '--group='),
          \ gina#util#shellescape(a:params.line, '--line='),
          \ gina#util#shellescape(a:params.col, '--col='),
          \ gina#util#shellescape(treeish),
          \)
  endif
endfunction

function! s:strip_conflict(content) abort
  let ff = &fileformat
  let newline = ff ==# 'unix' ? "\n" : ff ==# 'dos' ? "\r\n" : "\r"
  let text = s:String.join_posix_lines(a:content, "\n")
  let text = substitute(text, s:REGION_PATTERN, '', 'g')
  return s:String.split_posix_text(text, newline)
endfunction


" Config ---------------------------------------------------------------------
call gina#config(expand('<sfile>'), {
      \ 'use_default_mappings': 1,
      \})
