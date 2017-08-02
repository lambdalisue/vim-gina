let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#stash#call(range, args, mods) abort
  call gina#core#options#help_if_necessary(a:args, s:get_options_list())

  let git = gina#core#get_or_fail()
  let command = a:args.get(1, 'save')
  if command ==# 'show'
    return gina#command#stash#show#call(a:range, a:args, a:mods)
  elseif command !=# 'list'
    return gina#command#_raw#call(a:range, a:args, a:mods)
  endif
  " list
  let args = s:build_args(git, a:args)
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

function! gina#command#stash#complete(arglead, cmdline, cursorpos) abort
  let args = gina#core#args#new(matchstr(a:cmdline, '^.*\ze .*'))
  if args.get(1) =~# '^\%(list\|\)$'
    if a:arglead =~# '^-'
      let options = s:get_options_list()
      return options.complete(a:arglead, a:cmdline, a:cursorpos)
    endif
  elseif args.get(1) ==# 'show'
    return gina#command#stash#show#complete(a:arglead, a:cmdline, a:cursorpos)
  elseif args.get(1) ==# 'save'
    if a:arglead =~# '^-'
      let options = s:get_options_save()
      return options.complete(a:arglead, a:cmdline, a:cursorpos)
    endif
    return []
  elseif args.get(1) ==# 'drop'
    return gina#complete#stash#any(a:arglead, a:cmdline, a:cursorpos)
  elseif args.get(1) =~# '^\%(pop\|apply\)$'
    if a:arglead =~# '^-' || !empty(args.get(2))
      let options = s:get_options_pop()
      return options.complete(a:arglead, a:cmdline, a:cursorpos)
    endif
    return gina#complete#stash#any(a:arglead, a:cmdline, a:cursorpos)
  elseif args.get(1) ==# 'branch'
    if empty(args.get(2))
      return gina#complete#commit#branch(a:arglead, a:cmdline, a:cursorpos)
    endif
    return gina#complete#stash#any(a:arglead, a:cmdline, a:cursorpos)
  endif
  return gina#util#filter(a:arglead, [
        \ 'list',
        \ 'show',
        \ 'drop',
        \ 'pop',
        \ 'apply',
        \ 'branch',
        \ 'save',
        \ 'clear',
        \ 'create',
        \ 'store',
        \])
endfunction


" Private --------------------------------------------------------------------
function! s:get_options_list() abort
  let options = gina#core#options#new()
  call options.define(
        \ '-h|--help',
        \ 'Show this help.',
        \)
  call options.define(
        \ '--opener=',
        \ 'A Vim command to open a new buffer.',
        \ ['edit', 'split', 'vsplit', 'tabedit', 'pedit'],
        \)
  call options.define(
        \ '--group=',
        \ 'A window group name used for the buffer.',
        \)
  call options.define(
        \ '--follow',
        \ 'Continue listing the history of a file beyond renames',
        \)
  return options
endfunction

function! s:get_options_save() abort
  let options = gina#core#options#new()
  call options.define(
        \ '-h|--help',
        \ 'Show this help.',
        \)
  call options.define(
        \ '-k|--keep-index',
        \ 'Left intact all changes already added to the index',
        \)
  call options.define(
        \ '--no-keep-index',
        \ 'Do not left intact all changes already added to the index',
        \)
  call options.define(
        \ '-a|--all',
        \ 'The ignored files and untracked files are stashed and cleaned',
        \)
  call options.define(
        \ '--include-untracked',
        \ 'The untracked files are stashed and cleaned',
        \)
  return options
endfunction

function! s:get_options_pop() abort
  let options = gina#core#options#new()
  call options.define(
        \ '-h|--help',
        \ 'Show this help.',
        \)
  call options.define(
        \ '--index',
        \ 'Tries to reinstate not only the working tree but also index',
        \)
  return options
endfunction

function! s:build_args(git, args) abort
  let args = a:args.clone()
  let args.params.group = args.pop('--group', 'short')
  let args.params.opener = args.pop('--opener', &previewheight . 'split')

  return args.lock()
endfunction

function! s:init(args) abort
  call gina#core#meta#set('args', a:args)

  if exists('b:gina_initialized')
    return
  endif
  let b:gina_initialized = 1

  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nomodifiable
  setlocal autoread

  " Attach modules
  call gina#core#anchor#attach()
  call gina#action#attach(function('s:get_candidates'), {
        \ 'markable': 1,
        \})

  augroup gina_command_stash_list_internal
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer>
          \ call gina#core#exception#call(function('s:BufReadCmd'), [])
  augroup END
endfunction

function! s:BufReadCmd() abort
  let git = gina#core#get_or_fail()
  let args = gina#core#meta#get_or_fail('args')
  let pipe = gina#process#pipe#stream()
  let pipe.writer = gina#core#writer#new(extend(
        \ gina#process#pipe#stream_writer(),
        \ s:writer
        \))
  call gina#core#buffer#assign_cmdarg()
  call gina#process#open(git, args, pipe)
  setlocal filetype=gina-stash
endfunction

function! s:get_candidates(fline, lline) abort
  let candidates = map(
        \ getline(a:fline, a:lline),
        \ 's:parse_record(v:val)'
        \)
  return filter(candidates, '!empty(v:val)')
endfunction

function! s:parse_record(record) abort
  let stash = matchstr(a:record, '^[^:]\+')
  return {
        \ 'word': a:record,
        \ 'rev': stash,
        \ 'stash': stash,
        \}
endfunction


" Writer ---------------------------------------------------------------------
let s:writer = gina#util#inherit(gina#process#pipe#stream_writer())

function! s:writer.on_stop() abort
  call self.super(s:writer, 'on_stop')
  call gina#core#emitter#emit('command:called', s:SCHEME)
endfunction


" Config ---------------------------------------------------------------------
call gina#config(expand('<sfile>'), {
      \ 'use_default_aliases': 1,
      \ 'use_default_mappings': 1,
      \})
