let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#changes#call(range, args, mods) abort
  let git = gina#core#get_or_fail()
  let args = s:build_args(git, a:args)

  let bufname = gina#core#buffer#bufname(git, s:SCHEME, {
        \ 'rev': args.params.rev,
        \ 'params': [
        \   args.params.cached ? 'cached' : '',
        \   args.params.partial ? '--' : '',
        \ ],
        \})
  call gina#core#buffer#open(bufname, {
        \ 'mods': 'keepalt ' . a:mods,
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
  let args = a:args.clone()
  let args.params.group = args.pop('--group', '')
  let args.params.opener = args.pop('--opener', 'edit')
  let args.params.cached = args.get('--cached')
  let args.params.partial = !empty(args.residual())
  let args.params.rev = args.get(1, gina#core#buffer#param('%', 'rev'))

  call args.set('--numstat', 1)
  call args.set(0, 'diff')
  call args.set(1, args.params.rev)
  return args.lock()
endfunction

function! s:init(args) abort
  call gina#core#meta#set('args', a:args)

  if exists('b:gina_initialized')
    return
  endif
  let b:gina_initialized = 1

  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nomodifiable

  " Attach modules
  call gina#core#anchor#attach()
  call gina#action#attach(function('s:get_candidates'))

  augroup gina_command_changes_internal
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
  setlocal filetype=gina-changes
endfunction

function! s:get_candidates(fline, lline) abort
  let args = gina#core#meta#get_or_fail('args')
  let rev = args.params.rev
  let residual = args.residual()
  let candidates = map(
        \ getline(a:fline, a:lline),
        \ 's:parse_record(v:val, rev, residual)'
        \)
  return filter(candidates, '!empty(v:val)')
endfunction

function! s:parse_record(record, rev, residual) abort
  let m = matchlist(
        \ a:record,
        \ '^\(\d\+\)\s\+\(\d\+\)\s\+\(.\+\)$'
        \)
  return empty(m) ? {} : {
        \ 'word': a:record,
        \ 'added': m[1],
        \ 'removed': m[2],
        \ 'path': m[3],
        \ 'rev': a:rev,
        \ 'residual': a:residual,
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
