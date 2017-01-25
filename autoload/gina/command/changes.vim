let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')
let s:Observer = vital#gina#import('Vim.Buffer.Observer')


function! gina#command#changes#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)

  let bufname = printf(
        \ 'gina:%s:changes%s/%s',
        \ git.refname,
        \ args.params.cached ? ':cached' : '',
        \ args.params.commit,
        \)
  call gina#util#buffer#open(bufname, {
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
  let args.params = {}
  let args.params.async = args.pop('--async')
  let args.params.group = args.pop('--group', 'short')
  let args.params.opener = args.pop('--opener', &previewheight . 'split')
  let args.params.cmdarg = join([
        \ args.pop('^++enc'),
        \ args.pop('^++ff'),
        \])
  let args.params.cached = args.get('--cached')
  let args.params.commit = args.get(1, '')

  call args.set('--numstat', 1)
  call args.set(0, 'diff')
  call args.set(1, args.params.commit)
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
  call s:Anchor.attach()
  call s:Observer.attach()
  call gina#action#attach(function('s:get_candidates'))
  call gina#action#include('browse', 1)
  call gina#action#include('compare')
  call gina#action#include('diff')
  call gina#action#include('edit', 1)
  call gina#action#include('show')

  augroup gina_internal_command
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
  augroup END
endfunction

function! s:BufReadCmd() abort
  call gina#process#exec(
        \ gina#core#get_or_fail(),
        \ gina#util#meta#get_or_fail('args'),
        \)
  setlocal filetype=gina-changes
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
        \ '^\(\d\+\)\s\+\(\d\+\)\s\+\(.\+\)$'
        \)
  if empty(m)
    return {}
  endif
  return {
        \ 'word': a:record,
        \ 'added': m[1],
        \ 'removed': m[2],
        \ 'path': m[3],
        \}
endfunction
