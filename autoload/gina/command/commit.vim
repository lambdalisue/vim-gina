let s:String = vital#gina#import('Data.String')
let s:Git = vital#gina#import('Git')
let s:SCHEME = gina#command#scheme(expand('<sfile>'))

let s:SCISSOR = '------------------------ >8 ------------------------'
let s:messages = {}


function! gina#command#commit#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(a:args)

  if s:is_raw_command(args)
    return gina#command#_raw#call(a:range, a:args, a:mods)
  endif

  let bufname = gina#core#buffer#bufname(git, 'commit')
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

function! gina#command#commit#cleanup_commitmsg(content, mode, comment) abort
  let content = copy(a:content)
  if a:mode =~# '^\%(default\|strip\|whitespace\|scissors\)$'
    " Strip leading and trailing empty lines
    let content = split(
          \ substitute(join(content, "\n"), '^\n\+\|\n\+$', '', 'g'),
          \ "\n"
          \)
    " Strip trailing whitespace
    call map(content, 'substitute(v:val, ''\s\+$'', '''', '''')')
    " Remove content after a scissor
    if a:mode =~# '^\%(scissors\)$'
      let scissor = index(content, printf('%s %s', a:comment, s:SCISSOR))
      let content = scissor == -1 ? content : content[:scissor-1]
    endif
    " Strip commentary
    if a:mode =~# '^\%(default\|strip\|scissors\)$'
      call map(content, printf(
            \ 'v:val =~# ''^%s'' ? '''' : v:val',
            \ s:String.escape_pattern(a:comment)
            \))
    endif
    " Collapse consecutive empty lines
    let indices = range(len(content))
    let status = ''
    for index in reverse(indices)
      if empty(content[index]) && status ==# 'consecutive'
        call remove(content, index)
      else
        let status = empty(content[index]) ? 'consecutive' : ''
      endif
    endfor
  endif
  return content
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(args) abort
  let args = a:args.clone()
  let args.params.group = args.pop('--group', 'short')
  let args.params.opener = args.pop('--opener', &previewheight . 'split')
  let args.params.amend = args.get('--amend')
  return args.lock()
endfunction

function! s:is_raw_command(args) abort
  if a:args.get('-e|--edit')
    return 0
  elseif a:args.get('--no-edit')
    return 1
  elseif a:args.get('--dry-run')
    return 1
  elseif !empty(a:args.get('-C|--reuse-message', ''))
    return 1
  elseif !empty(a:args.get('-c|--reedit-message', ''))
    return 0
  elseif a:args.get('-F|--file')
    return 1
  elseif !empty(a:args.get('-m|--message', ''))
    return 1
  elseif a:args.get('-t|--template')
    return 0
  endif
  return 0
endfunction

function! s:init(args) abort
  call gina#core#meta#set('args', a:args)
  silent! unlet b:gina_QuitPre
  silent! unlet b:gina_BufWriteCmd

  if exists('b:gina_initialized')
    return
  endif
  let b:gina_initialized = 1

  setlocal nobuflisted
  setlocal buftype=acwrite
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal modifiable

  augroup gina_internal_command
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
    autocmd BufWriteCmd <buffer> call s:BufWriteCmd()
    autocmd QuitPre  <buffer> call s:QuitPre()
    autocmd WinLeave <buffer> call s:WinLeave()
    autocmd WinEnter <buffer> silent! unlet! b:gina_QuitPre
  augroup END

  nnoremap <silent><buffer> <Plug>(gina-commit-amend)
        \ :<C-u>call <SID>toggle_amend()<CR>
endfunction

function! s:BufReadCmd() abort
  let git = gina#core#get_or_fail()
  let args = gina#core#meta#get_or_fail('args')
  let content = gina#core#exception#call(
        \ function('s:get_commitmsg'),
        \ [git, args]
        \)
  call gina#core#buffer#assign_cmdarg()
  call gina#core#writer#assign_content(bufnr('%'), content)
  call gina#core#emitter#emit('command:called', s:SCHEME)
  setlocal filetype=gina-commit
endfunction

function! s:BufWriteCmd() abort
  let b:gina_BufWriteCmd = 1
  let git = gina#core#get_or_fail()
  let args = gina#core#meta#get_or_fail('args')
  call gina#core#exception#call(
        \ function('s:set_commitmsg'),
        \ [git, args, getline(1, '$')]
        \)
  setlocal nomodified
endfunction

function! s:QuitPre() abort
  let b:gina_QuitPre = 1
  silent! unlet b:gina_BufWriteCmd
endfunction

" NOTE:
" :w      -- BufWriteCmd
" <C-w>p  -- WinLeave
" :wq     -- QuitPre -> BufWriteCmd -> WinLeave
" :q      -- QuitPre -> WinLeave
function! s:WinLeave() abort
  if exists('b:gina_QuitPre')
    let git = gina#core#get_or_fail()
    let args = gina#core#meta#get_or_fail('args')
    if exists('b:gina_BufWriteCmd')
      " User execute 'wq' so do not confirm
      call gina#core#exception#call(
            \ function('s:commit_commitmsg'),
            \ [git, args]
            \)
    else
      " User execute 'q' so confirm
      call gina#core#exception#call(
            \ function('s:commit_commitmsg_confirm'),
            \ [git, args]
            \)
    endif
  endif
endfunction

function! s:toggle_amend() abort
  let args = gina#core#meta#get_or_fail('args')
  let args = args.clone()
  if args.get('--amend')
    call args.pop('--amend')
  else
    call args.set('--amend', 1)
  endif
  call gina#core#meta#set('args', args)
  edit
endfunction

function! s:get_commitmsg(git, args) abort
  let args = a:args.clone()
  let cname = args.get('--amend') ? 'amend' : '_'
  let commitmsg = s:get_cached_commitmsg(a:git, cname)

  let tempfile = tempname()
  try
    if !empty(commitmsg)
      call writefile(commitmsg, tempfile)
      call args.set('-F|--file', tempfile)
      call args.pop('-C|--reuse-message')
      call args.pop('-m|--message')
      call gina#core#console#debug('Use a cached commit message:')
      call gina#core#console#debug(join(map(copy(commitmsg), '''| '' . v:val'), "\n"))
    endif
    " Force edit mode
    call args.pop('--no-edit')
    call args.set('-e|--edit', 1)
    let result = gina#process#call(a:git, args)
    if !result.status
      " NOTE: Operation should be fail while GIT_EDITOR=false
      throw gina#process#error(result)
    endif
    " Get entire content (with comment) of commitmsg
    return s:get_commit_editmsg(a:git)
  finally
    call delete(tempfile)
  endtry
endfunction

function! s:set_commitmsg(git, args, content) abort
  let cname = a:args.get('--amend') ? 'amend' : '_'
  call s:set_commit_editmsg(a:git, a:content)
  call s:set_cached_commitmsg(a:git, cname, s:cleanup_commitmsg(
        \ a:git, a:args, a:content,
        \))
endfunction

function! s:commit_commitmsg(git, args) abort
  let config = gina#core#repo#config(a:git)
  let args = a:args.clone()
  let content = s:cleanup_commitmsg(
        \ a:git, a:args, s:get_commit_editmsg(a:git),
        \)
  let tempfile = tempname()
  try
    call writefile(content, tempfile)
    call args.set('--no-edit', 1)
    call args.set('-F|--file', tempfile)
    call args.pop('-C|--reuse-message')
    call args.pop('-m|--message')
    call args.pop('-e|--edit')
    let result = gina#process#call(a:git, args)
    call gina#process#inform(result)
    call s:remove_cached_commitmsg(a:git)
    call gina#core#emitter#emit('command:called:complete', s:SCHEME)
  finally
    call delete(tempfile)
  endtry
endfunction

function! s:commit_commitmsg_confirm(git, args) abort
  if gina#core#console#confirm('Do you want to commit changes?', 'y')
    call s:commit_commitmsg(a:git, a:args)
  else
    redraw | echo ''
  endif
endfunction

function! s:get_cleanup_mode(git, args, config) abort
  if a:args.get('--cleanup')
    return a:args.get('--cleanup')
  elseif a:args.get('--verbose')
    return 'scissors'
  endif
  if get(get(a:config, 'commit', {}), 'verbose', '') ==# 'true'
    return 'scissors'
  endif
  return get(get(a:config, 'commit', {}), 'cleanup', 'strip')
endfunction

function! s:cleanup_commitmsg(git, args, content) abort
  let config = gina#core#repo#config(a:git)
  let comment = get(get(config, 'core', {}), 'commentchar', '#')
  if a:args.get('--cleanup')
    let mode = a:args.get('--cleanup')
  elseif a:args.get('--verbose')
    let mode = 'scissors'
  elseif get(get(config, 'commit', {}), 'verbose', '') ==# 'true'
    let mode = 'scissors'
  else
    let mode = get(get(config, 'commit', {}), 'cleanup', 'strip')
  endif
  return gina#command#commit#cleanup_commitmsg(a:content, mode, comment)
endfunction

function! s:get_commit_editmsg(git) abort
  let path = s:Git.resolve(a:git, 'COMMIT_EDITMSG')
  return readfile(path)
endfunction

function! s:set_commit_editmsg(git, content) abort
  let path = s:Git.resolve(a:git, 'COMMIT_EDITMSG')
  return writefile(a:content, path)
endfunction

function! s:get_cached_commitmsg(git, name) abort
  let cname = a:git.worktree
  let s:messages[cname] = get(s:messages, cname, {})
  return get(s:messages[cname], a:name, [])
endfunction

function! s:set_cached_commitmsg(git, name, commitmsg) abort
  let cname = a:git.worktree
  let s:messages[cname] = get(s:messages, cname, {})
  let s:messages[cname][a:name] = a:commitmsg
endfunction

function! s:remove_cached_commitmsg(git) abort
  let cname = a:git.worktree
  let s:messages[cname] = {}
endfunction


call gina#config(expand('<sfile>'), {
      \ 'use_default_mappings': 1,
      \})
