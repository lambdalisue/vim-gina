let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')
let s:Config = vital#gina#import('Config')
let s:Observer = vital#gina#import('Vim.Buffer.Observer')


function! gina#command#tag#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)

  if s:is_raw_command(args)
    return gina#command#call('!', a:range, a:args, a:mods)
  endif

  let bufname = gina#core#buffer#bufname(git, 'tag')
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

  return args.lock()
endfunction

function! s:is_raw_command(args) abort
  if a:args.get('-l|--list')
    return 0
  elseif a:args.get('-a|--annotate|-s|--sign|-u|--local-user')
    return 1
  elseif a:args.get('-d|--delete')
    return 1
  elseif a:args.get('-v|--verify')
    return 1
  endif
  return 0
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
  call gina#action#include('branch')
  call gina#action#include('browse')
  call gina#action#include('changes')
  call gina#action#include('commit')
  call gina#action#include('info')

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
  setlocal filetype=gina-tag
endfunction

function! s:get_candidates(fline, lline) abort
  let git = gina#core#get_or_fail()
  let content = getline(a:fline, a:lline)
  let candidates = map(
        \ filter(content, '!empty(v:val)'),
        \ 's:parse_record(v:val)'
        \)
  return candidates
endfunction

function! s:parse_record(record) abort
  return {
        \ 'word': a:record,
        \ 'branch': a:record,
        \ 'revision': a:record,
        \}
endfunction


call s:Config.define('g:gina#command#tag', {
      \ 'use_default_aliases': 1,
      \ 'use_default_mappings': 1,
      \})
