let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')
let s:Argument = vital#gina#import('Argument')
let s:Emitter = vital#gina#import('Emitter')
let s:Observer = vital#gina#import('Vim.Buffer.Observer')
let s:String = vital#gina#import('Data.String')


function! gina#command#log#define() abort
  return s:command
endfunction


" Instance -------------------------------------------------------------------
let s:command = {}

function! s:command.command(range, qargs, qmods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:qargs)
  let bufname = printf(
        \ 'gina:%s:log/%s',
        \ git.refname,
        \ empty(args.params.path) ? '' : ':' . args.params.path,
        \)
  call gina#util#buffer#open(bufname, {
        \ 'mods': a:qmods,
        \ 'group': 'quick',
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
  let args = s:Argument.new(a:qargs)
  let args.params = {}
  let args.params.opener = args.pop('--opener', 'botright 10split')
  let args.params.cmdarg = join([
        \ args.pop('^++enc'),
        \ args.pop('^++ff'),
        \])
  let args.params.path = get(args.residual(), 0, '')

  if !empty(args.params.path)
    let args.params.path = gina#util#relpath(
          \ gina#util#expand(args.params.path)
          \)
  endif

  call args.set('--color', 'always')
  call args.set('--graph', 1)
  call args.set('--pretty', "format:\e[32m%h\e[m - %s \e[33;1m%cr\e[m \e[35;1m<%an>\e[m\e[36;1m%d\e[m")
  call args.residual([args.params.path])
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
  let result = gina#process#call(
        \ gina#core#get_or_fail(),
        \ gina#util#meta#get_or_fail('args').raw,
        \)
  if result.status
    throw gina#process#error(result)
  endif
  call gina#util#buffer#content(result.content)
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
  let commit = matchstr(record, '[a-z0-9]\+')
  let candidate = {
        \ 'word': record,
        \ 'abbr': a:record,
        \ 'commit': commit,
        \}
  return candidate
endfunction
