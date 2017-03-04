function! gina#action#blame#define(binder) abort
  if gina#core#buffer#param('%', 'scheme') ==# 'blame'
    call a:binder.define('blame:echo', function('s:on_echo'), {
          \ 'description': 'Echo a chunk info',
          \ 'mapping_mode': 'n',
          \ 'requirements': [
          \   'summary',
          \   'author',
          \   'author_time',
          \   'author_tz',
          \   'revision',
          \ ],
          \ 'options': {},
          \ 'use_marks': 0,
          \ 'clear_marks': 0,
          \})
    call a:binder.define('blame:open', function('s:on_open'), {
          \ 'description': 'Blame a content on a commit of a chunk',
          \ 'mapping_mode': 'n',
          \ 'requirements': ['rev', 'path'],
          \ 'options': {},
          \ 'use_marks': 0,
          \ 'clear_marks': 0,
          \})
    call a:binder.define('blame:back', function('s:on_back'), {
          \ 'description': 'Back to a navigational previous blame',
          \ 'mapping_mode': 'n',
          \ 'requirements': [],
          \ 'options': {},
          \ 'use_marks': 0,
          \ 'clear_marks': 0,
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
  redraw | call gina#core#console#info(printf(
        \ '%s: %s authored on %s [%s]',
        \ chunk.summary,
        \ chunk.author,
        \ timestamp,
        \ chunk.revision,
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
    if !has_key(chunk, 'previous')
      throw gina#core#exception#info(printf(
            \ 'No related parent commit exists and "%s" is already shown',
            \ chunk.rev,
            \))
    endif
    if !gina#core#console#confirm(printf(
          \ 'A related parent commit "%s" exist. Do you want to move on?',
          \ chunk.previous,
          \), 'y')
      throw gina#core#exception#info('Cancel')
    endif
    let rev = matchstr(chunk.previous, '^\S\+')
    let path = matchstr(chunk.previous, '^\S\+\s\zs.*')
    let line = v:null
  else
    let rev = chunk.rev
    let path = chunk.path
    let line = gina#util#get(chunk, 'line')
  endif
  call s:add_history()
  let treeish = gina#core#treeish#build(rev, path)
  execute printf(
        \ '%s Gina blame %s %s %s',
        \ options.mods,
        \ gina#util#shellescape(options.opener, '--opener='),
        \ gina#util#shellescape(line, '--line='),
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
        \ '%s Gina blame %s %s %s',
        \ options.mods,
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
