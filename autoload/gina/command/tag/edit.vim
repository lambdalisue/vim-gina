let s:String = vital#gina#import('Data.String')
let s:Git = vital#gina#import('Git')

let s:SCHEME = 'tag'


function! gina#command#tag#edit#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(a:args)

  let bufname = gina#core#buffer#bufname(git, s:SCHEME, {
        \ 'params': ['edit']
        \})
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
  return args.lock()
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

  augroup gina_command_tag_edit_internal
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
    autocmd BufWriteCmd <buffer> call s:BufWriteCmd()
    autocmd QuitPre  <buffer> call s:QuitPre()
    autocmd WinLeave <buffer> call s:WinLeave()
    autocmd WinEnter <buffer> silent! unlet! b:gina_QuitPre
  augroup END
endfunction

function! s:BufReadCmd() abort
  let git = gina#core#get_or_fail()
  let args = gina#core#meta#get_or_fail('args')
  let content = gina#core#exception#call(
        \ function('s:get_tagmsg_template'),
        \ [git, args]
        \)
  call gina#core#buffer#assign_cmdarg()
  call gina#core#writer#assign_content(v:null, content)
  call gina#core#emitter#emit('command:called', s:SCHEME)
  setlocal filetype=conf
endfunction

function! s:BufWriteCmd() abort
  let b:gina_BufWriteCmd = 1
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
            \ function('s:apply_tagmsg'),
            \ [git, args]
            \)
    else
      " User execute 'q' so confirm
      call gina#core#exception#call(
            \ function('s:apply_tagmsg_confirm'),
            \ [git, args]
            \)
    endif
  endif
endfunction

function! s:get_tagmsg_template(git, args) abort
  let config = gina#core#repo#config(a:git)
  let comment = get(config, 'core.commentchar', '#')
  let tagname = a:args.get(1)
  if a:args.get('--cleanup', 'strip') ==# 'strip'
    let template = [
          \ '',
          \ 'Write a message for tag:',
          \ '  ' . tagname,
          \ printf(
          \   'Lines starting with ''%s'' will be ignored.',
          \   comment,
          \ ),
          \]
  else
    let template = [
          \ '',
          \ 'Write a message for tag:',
          \ '  ' . tagname,
          \ printf(
          \   'Lines starting with ''%s'' will be kept; you may remove them yourself if you want to.',
          \   comment,
          \ ),
          \]
  endif
  call map(template, 'comment . '' '' . v:val')
  return [''] + template
endfunction

function! s:apply_tagmsg(git, args) abort
  let args = a:args.clone()
  let content = getline(1, '$')
  let tempfile = s:Git.resolve(a:git, 'TAG_EDITMSG')
  try
    call writefile(content, tempfile)
    call args.set('--cleanup', args.get('--cleanup', 'strip'))
    call args.set('-F|--file', tempfile)
    call args.pop('-m|--message')
    let result = gina#process#call(a:git, args)
    call gina#process#inform(result)
    call gina#core#emitter#emit('command:called:tag')
  finally
    call delete(tempfile)
  endtry
endfunction

function! s:apply_tagmsg_confirm(git, args) abort
  if gina#core#console#confirm('Do you want to create a tag?', 'y')
    call s:apply_tagmsg(a:git, a:args)
  else
    redraw | echo ''
  endif
endfunction


" Event ----------------------------------------------------------------------
function! s:on_command_called_tag(...) abort
  call gina#core#emitter#emit('modified:delay')
endfunction

if !exists('s:subscribed')
  let s:subscribed = 1
  call gina#core#emitter#subscribe(
        \ 'command:called:tag',
        \ function('s:on_command_called_tag')
        \)
endif
