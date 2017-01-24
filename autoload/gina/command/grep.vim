let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')
let s:Config = vital#gina#import('Config')
let s:Console = vital#gina#import('Vim.Console')
let s:Emitter = vital#gina#import('Emitter')
let s:Exception = vital#gina#import('Vim.Exception')
let s:Observer = vital#gina#import('Vim.Buffer.Observer')
let s:String = vital#gina#import('Data.String')


function! gina#command#grep#define() abort
  return s:command
endfunction


" Instance -------------------------------------------------------------------
let s:command = {}

function! s:command.command(range, qargs, qmods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:qargs)
  let bufname = printf(
        \ 'gina:%s:grep/%s',
        \ git.refname,
        \ args.params.commit,
        \)
  call gina#util#buffer#open(bufname, {
        \ 'mods': a:qmods,
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
function! s:build_args(git, qargs) abort
  let args = gina#command#parse(a:qargs)
  let args.params = {}
  let args.params.async = args.pop('--async')
  let args.params.group = args.pop('--group', 'quick')
  let args.params.opener = args.pop('--opener', &previewheight . 'split')
  let args.params.cmdarg = join([
        \ args.pop('^++enc'),
        \ args.pop('^++ff'),
        \])
  let args.params.pattern = args.pop(1, '')
  let args.params.commit = args.pop(1, '')

  " Check if available grep patterns has specified and ask if not
  if empty(args.params.pattern) && !(args.has('-e') || args.has('-f'))
    let pattern = s:Console.ask('Pattern: ')
    if empty(pattern)
      throw s:Exception.info('Cancel')
    endif
    let args.params.pattern = pattern
  endif

  call args.set('--line-number', 1)
  call args.set('--color', 'always')
  call args.set(1, args.params.pattern)
  call args.set(2, args.params.commit)
  return args.lock()
endfunction

function! s:init(args) abort
  call gina#util#meta#set('args', a:args)

  if exists('b:gina_initialized')
    return
  endif
  let b:gina_initialized = 1

  setlocal nobuflisted
  setlocal buftype=nofile
  setlocal bufhidden=unload
  setlocal noswapfile
  setlocal nomodifiable
  setlocal conceallevel=3 concealcursor=nvi

  " Attach modules
  call s:Anchor.attach()
  call s:Observer.attach()
  call gina#action#attach(function('s:get_candidates'))
  call gina#action#include('browse', 1)
  call gina#action#include('compare')
  call gina#action#include('diff')
  call gina#action#include('edit', 1)
  call gina#action#include('export', 1)
  call gina#action#include('patch')
  call gina#action#include('show')

  augroup gina_internal_command
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
  augroup END
endfunction

function! s:BufReadCmd() abort
  call gina#command#call(
        \ gina#core#get_or_fail(),
        \ gina#util#meta#get_or_fail('args'),
        \)
  setlocal filetype=gina-grep
endfunction

function! s:get_candidates(fline, lline) abort
  let git = gina#core#get_or_fail()
  let candidates = map(
        \ getline(a:fline, a:lline),
        \ 's:parse_record(git, v:val)'
        \)
  return filter(candidates, '!empty(v:val)')
endfunction

function! s:parse_record(git, record) abort
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
        \ 'path': gina#util#abspath(m[1]),
        \ 'line': line,
        \ 'col': col,
        \}
  return candidate
endfunction


cal s:Config.define('gina#command#grep', {
      \ 'send_to_quickfix': 1,
      \})
