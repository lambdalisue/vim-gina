let s:DateTime = vital#gina#import('DateTime')


function! gina#action#blame#define(binder) abort
  call a:binder.define('blame:open', function('s:on_open'), {
        \ 'description': 'Blame a content or enter the blame chunk',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['rev', 'path'],
        \ 'options': {},
        \})

  if gina#core#buffer#param('%', 'scheme') ==# 'blame'
    call a:binder.define('blame:back', function('s:on_back'), {
          \ 'description': 'Back to a navigational previous blame',
          \ 'mapping_mode': 'n',
          \ 'requirements': [],
          \ 'options': {},
          \})
    call a:binder.define('blame:echo', function('s:on_echo'), {
          \ 'description': 'Echo the chunk info',
          \ 'mapping_mode': 'n',
          \ 'requirements': [
          \   'rev',
          \   'summary',
          \   'author',
          \   'author_time',
          \   'author_tz',
          \ ],
          \ 'options': {},
          \})
  endif
endfunction


" Private --------------------------------------------------------------------
function! s:on_echo(candidates, options) abort dict
  if empty(a:candidates)
    return
  endif
  let chunk = a:candidates[0]
  let timestamp = gina#command#blame#timestamper#new().format(
        \ chunk.author_time,
        \ chunk.author_tz,
        \)
  let revision = chunk.rev
  if has_key(chunk, 'previous')
    let revision = printf('%s <- %s', revision, chunk.previous)
  endif
  redraw | call gina#core#console#info(printf(
        \ '%s by %s %s (%s)',
        \ chunk.summary,
        \ chunk.author,
        \ timestamp,
        \ revision,
        \))
endfunction

function! s:on_open(candidates, options) abort dict
  if empty(a:candidates)
    return
  endif
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  let args = gina#core#meta#get_or_fail('args')
  let chunk = a:candidates[0]
  if !empty(args.params.rev) && chunk.rev =~# '^' . args.params.rev
    throw gina#core#exception#info(printf(
          \ 'No related parent commit exists and "%s" is already shown',
          \ chunk.rev,
          \))
  endif
  call s:add_history()
  let treeish = gina#core#treeish#build(chunk.rev, chunk.path)
  execute printf(
        \ 'Gina blame %s %s %s',
        \ gina#util#shellescape(options.opener, '--opener='),
        \ gina#util#shellescape(gina#util#get(chunk, 'line'), '--line='),
        \ gina#util#shellescape(treeish),
        \)
endfunction

function! s:on_back(candidates, options) abort dict
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  let history = s:pop_history()
  let treeish = gina#core#treeish#build(history.rev, history.path)
  execute printf(
        \ 'Gina blame %s %s %s',
        \ gina#util#shellescape(options.opener, '--opener='),
        \ gina#util#shellescape(history.line, '--line='),
        \ gina#util#shellescape(treeish),
        \)
endfunction


" History --------------------------------------------------------------------
function! s:add_history() abort
  if gina#core#buffer#param('%', 'scheme') !=# 'blame'
    return
  endif
  let w:gina_blame_history = get(w:, 'gina_blame_history', [])
  let args = gina#core#meta#get_or_fail('args')
  call add(w:gina_blame_history, {
        \ 'rev': empty(args.params.rev) ? ':0' : args.params.rev,
        \ 'path': args.params.path,
        \ 'line': line('.'),
        \})
endfunction

function! s:pop_history() abort
  let w:gina_blame_history = get(w:, 'gina_blame_history', [])
  if empty(w:gina_blame_history)
    throw gina#core#exception#info('No navigational history is found')
  endif
  return remove(w:gina_blame_history, -1)
endfunction
