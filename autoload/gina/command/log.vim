let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')
let s:Config = vital#gina#import('Config')
let s:Observer = vital#gina#import('Vim.Buffer.Observer')
let s:String = vital#gina#import('Data.String')


function! gina#command#log#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let bufname = gina#core#buffer#bufname(git, 'log', {
        \ 'relpath': gina#core#repo#relpath(git, args.params.abspath),
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
function! s:build_args(git, args) abort
  let args = gina#command#parse_args(a:args)
  let args.params.group = args.pop('--group', 'short')
  let args.params.opener = args.pop('--opener', &previewheight . 'split')

  let pathlist = map(copy(args.residual()), 'gina#core#path#abspath(v:val)')
  if len(pathlist) == 1
    let args.params.abspath = pathlist[0]
  else
    let args.params.abspath = ''
  endif

  call args.set('--color', 'always')
  call args.set('--graph', 1)
  call args.set('--pretty', "format:\e[32m%h\e[m - %s \e[33;1m%cr\e[m \e[35;1m<%an>\e[m\e[36;1m%d\e[m")
  call args.residual(pathlist)
  return args.lock()
endfunction

function! s:init(args) abort
  call gina#core#meta#set('args', a:args)

  if exists('b:gina_initialized')
    return
  endif
  let b:gina_initialized = 1

  setlocal nobuflisted
  setlocal buftype=nofile
  setlocal bufhidden=delete
  setlocal noswapfile
  setlocal nomodifiable

  " Attach modules
  call s:Anchor.attach()
  call s:Observer.attach()
  call gina#action#attach(function('s:get_candidates'))
  call gina#action#include('browse')
  call gina#action#include('changes')
  call gina#action#include('commit')
  call gina#action#include('compare')
  call gina#action#include('diff')
  call gina#action#include('edit')
  call gina#action#include('info')
  call gina#action#include('show')

  augroup gina_internal_command
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
  augroup END
endfunction

function! s:BufReadCmd() abort
  call gina#process#exec(
        \ gina#core#get_or_fail(),
        \ gina#core#meta#get_or_fail('args'),
        \)
  setlocal filetype=gina-log
endfunction

function! s:get_candidates(fline, lline) abort
  let git = gina#core#get_or_fail()
  let relpath = gina#core#buffer#param('%', 'relpath')
  let abspath = gina#core#repo#abspath(git, relpath)
  let candidates = map(
        \ filter(getline(a:fline, a:lline), '!empty(v:val)'),
        \ 's:parse_record(abspath, v:val)'
        \)
  return candidates
endfunction

function! s:parse_record(abspath, record) abort
  let record = s:String.remove_ansi_sequences(a:record)
  let revision = matchstr(record, '[a-z0-9]\+')
  let candidate = {
        \ 'word': record,
        \ 'abbr': a:record,
        \ 'path': a:abspath,
        \ 'revision': revision,
        \}
  return candidate
endfunction


call s:Config.define('g:gina#command#log', {
      \ 'use_default_aliases': 1,
      \ 'use_default_mappings': 1,
      \})
