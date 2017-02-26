let s:String = vital#gina#import('Data.String')
let s:Git = vital#gina#import('Git')

let s:SCHEME = gina#command#scheme(expand('<sfile>'))
let s:messages = {}


function! gina#command#commit#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(a:args)

  if s:is_raw_command(args)
    return gina#command#_raw#call(a:range, a:args, a:mods)
  endif

  let bufname = gina#core#buffer#bufname(git, s:SCHEME)
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

  augroup gina_command_commit_internal
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
  call gina#core#writer#assign_content(v:null, content)
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

function! s:get_cleanup(git, args) abort
  let config = gina#core#repo#config(a:git)
  if a:args.get('--cleanup')
    return a:args.get('--cleanup')
  endif
  return get(get(config, 'commit', {}), 'cleanup', 'strip')
endfunction

function! s:get_commitmsg(git, args) abort
  let content = s:get_cached_commitmsg(a:git, a:args)
  if empty(content)
    return s:get_commitmsg_template(a:git, a:args)
  else
    call gina#core#console#debug('Use a cached commit message:')
    return s:get_commitmsg_cleanedup(a:git, a:args, content)
  endif
endfunction

function! s:get_commitmsg_template(git, args) abort
  let args = a:args.clone()
  let filename = s:Git.resolve(a:git, 'COMMIT_EDITMSG')
  let previous_content = readfile(filename)
  try
    " Build a new commit message template
    call args.pop('--no-edit')
    call args.set('-e|--edit', 1)
    let result = gina#process#call(a:git, args)
    if !result.status
      " While git is executed with '-c core.editor=false', the command above
      " should fail after that create a COMMIT_EDITMSG for the current
      " situation
      throw gina#process#errormsg(result)
    endif
    " Get a built commitmsg template
    return readfile(filename)
  finally
    " Restore the content
    call writefile(previous_content, filename)
  endtry
endfunction

" Note:
" Commit the cached messate temporary to build a correct COMMIT_EDITMSG
" This hacky implementation is required due to the lack of cleanup command.
" https://github.com/lambdalisue/gina.vim/issues/37#issuecomment-281661605
" Note:
" It is not possible to remove diff content when user does
"   1. Gina commit --verbose
"   2. Save content
"   3. Gina commit
"   4. The diff part is cached so shown and no chance to remove that
" This is a bit anoyying but I don't have any way to remove that so I just
" ended up. PRs for this issue is welcome.
" https://github.com/lambdalisue/gina.vim/issues/37#issuecomment-281687325
function! s:get_commitmsg_cleanedup(git, args, content) abort
  let args = a:args.clone()
  let filename = s:Git.resolve(a:git, 'COMMIT_EDITMSG')
  let previous_content = readfile(filename)
  let tempfile = tempname()
  try
    call writefile(a:content, tempfile)
    call args.set('--cleanup', s:get_cleanup(a:git, args))
    call args.set('-F|--file', tempfile)
    call args.set('--no-edit', 1)
    call args.set('--allow-empty', 1)
    call args.set('--allow-empty-message', 1)
    call args.pop('-C|--reuse-message')
    call args.pop('-m|--message')
    call args.pop('-e|--edit')
    call gina#process#call_or_fail(a:git, args)
    " Reset the temporary commit and remove all logs
    call gina#process#call_or_fail(a:git, ['reset', '--soft', 'HEAD@{1}'])
    call gina#process#call_or_fail(a:git, ['reflog', 'delete', 'HEAD@{0}'])
    call gina#process#call_or_fail(a:git, ['reflog', 'delete', 'HEAD@{0}'])
    " Get entire content of commitmsg
    return readfile(filename)
  finally
    call delete(tempfile)
    call writefile(previous_content, filename)
  endtry
endfunction

function! s:set_commitmsg(git, args, content) abort
  call s:set_cached_commitmsg(a:git, a:args, a:content)
endfunction

function! s:commit_commitmsg(git, args) abort
  let config = gina#core#repo#config(a:git)
  let args = a:args.clone()
  let content = s:get_cached_commitmsg(a:git, args)
  let tempfile = tempname()
  try
    call writefile(content, tempfile)
    call args.set('--no-edit', 1)
    call args.set('--cleanup', s:get_cleanup(a:git, args))
    call args.set('-F|--file', tempfile)
    call args.pop('-C|--reuse-message')
    call args.pop('-m|--message')
    call args.pop('-e|--edit')
    let result = gina#process#call(a:git, args)
    call gina#process#inform(result)
    call s:remove_cached_commitmsg(a:git)
    call gina#core#emitter#emit('command:called:commit')
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

function! s:get_cached_commitmsg(git, args) abort
  let wname = a:git.worktree
  let cname = a:args.get('--amend') ? 'amend' : '_'
  let s:messages[wname] = get(s:messages, wname, {})
  return get(s:messages[wname], cname, [])
endfunction

function! s:set_cached_commitmsg(git, args, commitmsg) abort
  let wname = a:git.worktree
  let cname = a:args.get('--amend') ? 'amend' : '_'
  let s:messages[wname] = get(s:messages, wname, {})
  let s:messages[wname][cname] = a:commitmsg
endfunction

function! s:remove_cached_commitmsg(git) abort
  let cname = a:git.worktree
  let s:messages[cname] = {}
endfunction


" Event ----------------------------------------------------------------------
function! s:on_command_called_commit(...) abort
  call gina#core#emitter#emit('modified:delay')
endfunction

if !exists('s:subscribed')
  let s:subscribed = 1
  call gina#core#emitter#subscribe(
        \ 'command:called:commit',
        \ function('s:on_command_called_commit')
        \)
endif


" Config ---------------------------------------------------------------------
call gina#config(expand('<sfile>'), {
      \ 'use_default_mappings': 1,
      \})
