let s:Argument = vital#gina#import('Argument')
let s:Emitter = vital#gina#import('Emitter')


function! gina#command#ls_files#command(range, qargs, qmods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:qargs)
  let bufname = printf(
        \ 'gina:%s:ls-files',
        \ git.refname,
        \)
  call gina#util#buffer#open(bufname, {
        \ 'group': 'quick',
        \ 'opener': args.params.opener,
        \ 'callback': {
        \   'fn': function('s:init'),
        \   'args': [args],
        \ }
        \})
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, qargs) abort
  let args = s:Argument.new(a:qargs)
  let args.params.opener = args.pop('--opener', 'botright 10split')

  call args.set('--full-name', 1)
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

  " Attach modules
  call gina#util#command#attach()
  call gina#util#command#async#attach()
  call gina#action#attach(function('s:get_candidates'))
  call gina#action#include('browse')
  call gina#action#include('compare')
  call gina#action#include('diff')
  call gina#action#include('edit')
  call gina#action#include('show')

  augroup gina_internal_command
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
  augroup END
endfunction

function! s:BufReadCmd() abort
  let git = gina#core#get_or_fail()
  let args = gina#util#meta#get_or_fail('args')

  call gina#util#command#async#call(git, args.raw)

  setlocal filetype=gina-ls-files
endfunction

function! s:get_candidates(fline, lline) abort
  let candidates = map(
        \ filter(getline(a:fline, a:lline), '!empty(v:val)'),
        \ 's:parse_record(v:val)'
        \)
  return candidates
endfunction

function! s:parse_record(record) abort
  let candidate = {
        \ 'word': a:record,
        \ 'path': a:record,
        \}
  return candidate
endfunction
