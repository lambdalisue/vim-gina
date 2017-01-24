let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')
let s:Observer = vital#gina#import('Vim.Buffer.Observer')


function! gina#command#tag#define() abort
  return s:command
endfunction


" Instance -------------------------------------------------------------------
let s:command = {}

function! s:command.command(range, qargs, qmods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:qargs)

  if s:is_raw_command(args)
    return gina#router#command#call('!', a:range, a:qargs, a:qmods)
  endif

  let bufname = printf('gina:%s:tag', git.refname)
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
  let args.params.group = args.pop('--group', 'short')
  let args.params.opener = args.pop('--opener', &previewheight . 'split')
  let args.params.cmdarg = join([
        \ args.pop('^++enc'),
        \ args.pop('^++ff'),
        \])

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
  setlocal conceallevel=3 concealcursor=nvic

  " Attach modules
  call s:Anchor.attach()
  call s:Observer.attach()
  call gina#action#attach(function('s:get_candidates'))
  call gina#action#include('branch', 1)
  call gina#action#include('browse', 1)
  call gina#action#include('changes')
  call gina#action#include('commit', 1)
  call gina#action#include('show', 1)

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
        \ 'commit': a:record,
        \}
endfunction
