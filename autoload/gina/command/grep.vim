let s:String = vital#gina#import('Data.String')

let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#grep#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let bufname = gina#core#buffer#bufname(git, s:SCHEME, {
        \ 'rev': args.params.rev,
        \ 'params': [
        \   args.params.partial ? '--' : '',
        \ ],
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

function! gina#command#grep#parse_record(...) abort
  return call('s:parse_record', a:000)
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = a:args.clone()
  let args.params.group = args.pop('--group', 'short')
  let args.params.opener = args.pop('--opener', &previewheight . 'split')
  let args.params.pattern = args.pop(1, '')
  let args.params.partial = !empty(args.residual())
  let args.params.rev = args.pop(1, gina#core#buffer#param('%', 'rev'))

  " Check if available grep patterns has specified and ask if not
  if empty(args.params.pattern) && !(args.has('-e') || args.has('-f'))
    let pattern = gina#core#console#ask('Pattern: ')
    if empty(pattern)
      throw gina#core#exception#info('Cancel')
    endif
    let args.params.pattern = pattern
  endif

  call args.set('--line-number', 1)
  call args.set('--color', 'always')
  call args.set(1, args.params.pattern)
  call args.set(2, args.params.rev)
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

  " Attach modules
  call gina#core#anchor#attach()
  call gina#action#attach(function('s:get_candidates'))

  augroup gina_command_grep_internal
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
  setlocal filetype=gina-grep
endfunction

function! s:get_candidates(fline, lline) abort
  let args = gina#core#meta#get_or_fail('args')
  let rev = args.params.rev
  let residual = args.residual()
  let candidates = map(
        \ getline(a:fline, a:lline),
        \ 's:parse_record(v:val, rev, residual)'
        \)
  return filter(candidates, '!empty(v:val)')
endfunction

function! s:parse_record(record, rev, residual) abort
  let record = s:String.remove_ansi_sequences(a:record)
  let m = matchlist(record, '^\%([^:]\+:\)\?\(.*\):\(\d\+\):\(.*\)$')
  if empty(m)
    return {}
  endif
  let matched = matchstr(a:record, '\e\[1;31m\zs.\{-}\ze\e\[m')
  let line = str2nr(m[2])
  let col = stridx(m[3], matched) + 1
  let candidate = {
        \ 'word': m[3],
        \ 'abbr': a:record,
        \ 'line': line,
        \ 'col': col,
        \ 'path': m[1],
        \ 'rev': a:rev,
        \ 'residual': a:residual,
        \}
  return candidate
endfunction


" Writer ---------------------------------------------------------------------
let s:writer = gina#util#inherit(gina#process#pipe#stream_writer())

function! s:writer.on_stop() abort
  call self.super(s:writer, 'on_stop')
  call gina#core#emitter#emit('command:called', s:SCHEME)
endfunction


" Config ---------------------------------------------------------------------
call gina#config(expand('<sfile>'), {
      \ 'send_to_quickfix': 1,
      \ 'use_default_aliases': 1,
      \ 'use_default_mappings': 1,
      \})
