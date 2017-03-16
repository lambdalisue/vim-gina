let s:Path = vital#gina#import('System.Filepath')
let s:String = vital#gina#import('Data.String')

let s:SCHEME = gina#command#scheme(expand('<sfile>'))
let s:ALLOWED_OPTIONS = [
      \ '--opener=',
      \ '--group=',
      \ '-D', '-d', '--delete',
      \ '-l', '--create-reflog',
      \ '-f', '--force',
      \ '-M', '-m', '--move',
      \ '-i', '--ignore-case',
      \ '-r', '--remotes',
      \ '-a', '--all',
      \ '--list',
      \ '-v', '-vv', '--verbose',
      \ '-q', '--quiet',
      \ '-t', '--track', '--no-track',
      \ '--set-upstream',
      \ '-u', '--set-upstream-to=',
      \ '--unset-upstream',
      \ '--contains=',
      \ '--merged=',
      \ '--no-merged=',
      \ '--sort=',
      \ '--points-at=',
      \]


function! gina#command#branch#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)

  if s:is_raw_command(args)
    return gina#command#_raw#call(a:range, a:args, a:mods)
  endif

  let bufname = gina#core#buffer#bufname(git, s:SCHEME)
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

function! gina#command#branch#complete(arglead, cmdline, cursorpos) abort
  let args = gina#core#args#new(matchstr(a:cmdline, '^.*\ze .*'))
  if a:arglead =~# '^--opener='
    return gina#complete#common#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^\%(-u\|--set-upstream-to=\)'
    let leading = matchstr(a:arglead, '^\%(-u\|--set-upstream-to=\)')
    let candidates = gina#complete#commit#branch(
          \ matchstr(a:arglead, '^' . leading . '\zs.*'),
          \ a:cmdline,
          \ a:cursorpos
          \)
    return map(candidates, 'leading . v:val')
  elseif a:arglead =~# '^\%(--contains\|--merged\|--no-merged\|--points-at\)='
    let leading = matchstr(
          \ a:arglead,
          \ '^\%(--contains\|--merged\|--no-merged\|--points-at\)='
          \)
    let candidates = gina#complete#commit#any(
          \ matchstr(a:arglead, '^' . leading . '\zs.*'),
          \ a:cmdline,
          \ a:cursorpos
          \)
    return map(candidates, 'leading . v:val')
  elseif a:arglead[0] ==# '-'
    return gina#util#filter(a:arglead, s:ALLOWED_OPTIONS)
  endif
  return gina#complete#commit#branch(a:arglead, a:cmdline, a:cursorpos)
endfunction


" Private --------------------------------------------------------------------
function! s:build_args(git, args) abort
  let args = a:args.clone()
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
  endif
  return !empty(a:args.get(1))
endfunction

function! s:init(args) abort
  call gina#core#meta#set('args', a:args)

  if exists('b:gina_initialized')
    return
  endif
  let b:gina_initialized = 1

  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nomodifiable
  setlocal autoread

  " Attach modules
  call gina#core#anchor#attach()
  call gina#action#attach(function('s:get_candidates'), {
        \ 'markable': 1,
        \})

  augroup gina_command_branch_internal
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:BufReadCmd()
  augroup END
endfunction

function! s:BufReadCmd() abort
  let git = gina#core#get_or_fail()
  let args = gina#core#meta#get_or_fail('args')
  let pipe = gina#process#pipe#stream()
  let pipe.writer = gina#core#writer#new(extend(
        \ gina#process#pipe#stream_writer(),
        \ s:writer
        \))
  call gina#core#buffer#assign_cmdarg()
  call gina#process#open(git, args, pipe)
  setlocal filetype=gina-branch
endfunction

function! s:get_candidates(fline, lline) abort
  let candidates = map(
        \ getline(a:fline, a:lline),
        \ 's:parse_record(v:val)'
        \)
  return filter(candidates, '!empty(v:val)')
endfunction

function! s:parse_record(record) abort
  let record = s:String.remove_ansi_sequences(a:record)
  let m = matchlist(record, '\(\*\|\s\) \([^ ]\+\)\%( -> \([^ ]\+\)\)\?')
  let remote = matchstr(m[2], '^remotes/\zs[^ /]\+')
  let rev = matchstr(m[2], '^\%(remotes/\)\?\zs[^ ]\+')
  let branch = matchstr(rev, printf('^\%%(%s/\)\?\zs[^ ]\+', remote))
  return {
        \ 'word': record,
        \ 'abbr': a:record,
        \ 'sign': m[1],
        \ 'alias': m[3],
        \ 'remote': remote,
        \ 'rev': rev,
        \ 'branch': branch,
        \}
endfunction


" Writer ---------------------------------------------------------------------
let s:writer = gina#util#inherit(gina#process#pipe#stream_writer())

function! s:writer.on_stop() abort
  call self.super(s:writer, 'on_stop')
  call gina#core#emitter#emit('command:called', s:SCHEME)
endfunction


" Config ---------------------------------------------------------------------
call gina#config(expand('<sfile>'), {
      \ 'use_default_aliases': 1,
      \ 'use_default_mappings': 1,
      \})
