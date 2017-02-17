let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')
let s:Config = vital#gina#import('Config')
let s:Observer = vital#gina#import('Vim.Buffer.Observer')
let s:Path = vital#gina#import('System.Filepath')
let s:String = vital#gina#import('Data.String')


function! gina#command#branch#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)

  if s:is_raw_command(args)
    return gina#command#call('!', a:range, a:args, a:mods)
  endif

  let bufname = gina#core#buffer#bufname(git, 'branch')
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

  call args.set('--color', 'always')
  return args.lock()
endfunction

function! s:is_raw_command(args) abort
  if a:args.get('--list')
    return 0
  elseif !empty(a:args.get('-u|--set-upstream-to', ''))
    return 1
  elseif a:args.get('--unset-upstream')
    return 1
  elseif a:args.get('-m|--move') || a:args.get('-M')
    return 1
  elseif a:args.get('-d|--delete') || a:args.get('-D')
    return 1
  elseif a:args.get('--edit-description')
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
  " Without 'autoread', branch manipulation action requires ':e' to reload
  " while Vim.Buffer.Observer does not update a buffer without 'autoread'
  setlocal autoread

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
  setlocal filetype=gina-branch
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
  let record = s:String.remove_ansi_sequences(a:record)
  let m = matchlist(record, '\(\*\|\s\) \([^ ]\+\)\%( -> \([^ ]\+\)\)\?')
  let remote = matchstr(m[2], '^remotes/\zs[^ /]\+')
  let revision = matchstr(m[2], '^\%(remotes/\)\?\zs[^ ]\+')
  let branch = matchstr(revision, printf('^\%%(%s/\)\?\zs[^ ]\+', remote))
  return {
        \ 'word': record,
        \ 'abbr': a:record,
        \ 'sign': m[1],
        \ 'alias': m[3],
        \ 'remote': remote,
        \ 'revision': revision,
        \ 'branch': branch,
        \}
endfunction


call s:Config.define('g:gina#command#branch', {
      \ 'use_default_aliases': 1,
      \ 'use_default_mappings': 1,
      \})
