let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')
let s:String = vital#gina#import('Data.String')
let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#grep#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let bufname = gina#core#buffer#bufname(git, 'grep', {
        \ 'revision': args.params.revision,
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

function! gina#command#grep#parse_record(git, revision, record) abort
  return s:parse_record(a:git, a:revision, a:record)
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = gina#command#parse_args(a:args)
  let args.params.group = args.pop('--group', 'quick')
  let args.params.opener = args.pop('--opener', &previewheight . 'split')
  let args.params.pattern = args.pop(1, '')
  let args.params.revision = args.pop(1, gina#core#buffer#param('%', 'revision'))

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
  call args.set(2, args.params.revision)
  return args.lock()
endfunction

function! s:init(args) abort
  call gina#core#meta#set('args', a:args)

  if exists('b:gina_initialized')
    return
  endif
  let b:gina_initialized = 1

  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nomodifiable

  " Attach modules
  call s:Anchor.attach()
  call gina#action#attach(function('s:get_candidates'))
  call gina#action#include('browse')
  call gina#action#include('compare')
  call gina#action#include('diff')
  call gina#action#include('edit')
  call gina#action#include('export')
  call gina#action#include('patch')
  call gina#action#include('show')

  augroup gina_internal_command
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
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
  call gina#process#open(git, args, pipe)
  setlocal filetype=gina-grep
endfunction

function! s:get_candidates(fline, lline) abort
  let git = gina#core#get_or_fail()
  let revision = gina#core#buffer#param('%', 'revision')
  let candidates = map(
        \ getline(a:fline, a:lline),
        \ 's:parse_record(git, revision, v:val)'
        \)
  return filter(candidates, '!empty(v:val)')
endfunction

function! s:parse_record(git, revision, record) abort
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
        \ 'path': gina#core#repo#abspath(a:git, m[1]),
        \ 'revision': a:revision,
        \}
  return candidate
endfunction


" Writer ---------------------------------------------------------------------
let s:writer_super = gina#process#pipe#stream_writer()
let s:writer = {}

function! s:writer.on_stop() abort
  call call(s:writer_super.on_stop, [], self)
  call gina#core#emitter#emit('command:called', s:SCHEME)
endfunction


call gina#config(expand('<sfile>'), {
      \ 'send_to_quickfix': 1,
      \ 'use_default_aliases': 1,
      \ 'use_default_mappings': 1,
      \})
