let s:Argument = vital#gina#import('Argument')
let s:Config = vital#gina#import('Config')
let s:Path = vital#gina#import('System.Filepath')


function! gina#command#status#command(range, qargs, qmods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:qargs)
  let bufname = printf(
        \ 'gina:%s:status',
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
  call args.set('--porcelain', 1)
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
  call gina#action#include('export')
  call gina#action#include('index')
  call gina#action#include('patch')
  call gina#action#include('show')

  augroup gina_internal_command
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
  augroup END

  nnoremap <silent><buffer>
        \ <Plug>(gina-status-commit)
        \ :<C-u>Gina commit<CR>
endfunction

function! s:BufReadCmd() abort
  let git = gina#core#get_or_fail()
  let args = gina#util#meta#get_or_fail('args')

  call gina#util#command#async#call(git, args.raw)

  setlocal filetype=gina-status
endfunction

function! s:compare_record(a, b) abort
  let a = matchstr(a:a, '...\zs.*')
  let b = matchstr(a:b, '...\zs.*')
  return a ==# b ? 0 : a > b ? 1 : -1
endfunction

function! s:get_candidates(fline, lline) abort
  let git = gina#core#get_or_fail()
  let candidates = map(
        \ getline(a:fline, a:lline),
        \ 's:parse_record(v:val)'
        \)
  call filter(candidates, '!empty(v:val)')
  return candidates
endfunction

function! s:parse_record(record) abort
  let m = matchlist(
        \ a:record,
        \ '^\(..\) \("[^"]\{-}"\|.\{-}\)\%( -> \("[^"]\{-}"\|[^ ]\+\)\)\?$'
        \)
  if len(m) && !empty(m[3])
    return {
          \ 'word': a:record,
          \ 'sign': m[1],
          \ 'path': s:strip_quotes(m[3]),
          \ 'path1': s:strip_quotes(m[2]),
          \ 'path2': s:strip_quotes(m[3]),
          \}
  elseif len(m) && !empty(m[2])
    return {
          \ 'word': a:record,
          \ 'sign': m[1],
          \ 'path': s:strip_quotes(m[2]),
          \ 'path1': s:strip_quotes(m[2]),
          \ 'path2': '',
          \}
  else
    return {}
  endif
endfunction

function! s:strip_quotes(str) abort
  return a:str =~# '^\%(".*"\|''.*''\)$' ? a:str[1:-2] : a:str
endfunction
