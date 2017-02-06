let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')
let s:Config = vital#gina#import('Config')
let s:Observer = vital#gina#import('Vim.Buffer.Observer')
let s:String = vital#gina#import('Data.String')


function! gina#command#log#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)
  let bufname = printf(
        \ 'gina:%s:log/%s',
        \ git.refname,
        \ empty(args.params.path)
        \   ? ''
        \   : ':' . gina#core#repo#objpath(git, args.params.path),
        \)
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
  let args.params = {}
  let args.params.async = args.pop('--async')
  let args.params.group = args.pop('--group', 'short')
  let args.params.opener = args.pop('--opener', &previewheight . 'split')
  let args.params.cmdarg = join([
        \ args.pop('^++enc'),
        \ args.pop('^++ff'),
        \])
  let args.params.path = get(args.residual(), 0, '')

  if !empty(args.params.path)
    let args.params.path = gina#core#repo#relpath(
          \ a:git,
          \ gina#core#repo#expand(args.params.path)
          \)
  endif

  call args.set('--color', 'always')
  call args.set('--graph', 1)
  call args.set('--pretty', "format:\e[32m%h\e[m - %s \e[33;1m%cr\e[m \e[35;1m<%an>\e[m\e[36;1m%d\e[m")
  call args.residual([args.params.path])
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
  setlocal bufhidden=unload
  setlocal noswapfile
  setlocal nomodifiable
  setlocal conceallevel=3 concealcursor=nvi

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
  call gina#action#include('show')

  augroup gina_internal_command
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
  augroup END
endfunction

function! s:BufReadCmd() abort
  call gina#core#process#exec(
        \ gina#core#get_or_fail(),
        \ gina#core#meta#get_or_fail('args'),
        \)
  setlocal filetype=gina-log
endfunction

function! s:get_candidates(fline, lline) abort
  let candidates = map(
        \ filter(getline(a:fline, a:lline), '!empty(v:val)'),
        \ 's:parse_record(v:val)'
        \)
  return candidates
endfunction

function! s:parse_record(record) abort
  let record = s:String.remove_ansi_sequences(a:record)
  let revision = matchstr(record, '[a-z0-9]\+')
  let candidate = {
        \ 'word': record,
        \ 'abbr': a:record,
        \ 'revision': revision,
        \}
  return candidate
endfunction


call s:Config.define('g:gina#command#log', {
      \ 'use_default_aliases': 1,
      \ 'use_default_mappings': 1,
      \})
