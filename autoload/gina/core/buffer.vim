let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')
let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Exception = vital#gina#import('Vim.Exception')
let s:Guard = vital#gina#import('Vim.Guard')
let s:Opener = vital#gina#import('Vim.Buffer.Opener')
let s:Path = vital#gina#import('System.Filepath')
let s:Window = vital#gina#import('Vim.Window')
let s:DEFAULT_PARAMS_ATTRIBUTES = {
      \ 'repo': '',
      \ 'scheme': '',
      \ 'params': [],
      \ 'revision': '',
      \ 'relpath': '',
      \}


function! gina#core#buffer#bufname(git, scheme, ...) abort
  let options = extend({
        \ 'params': [],
        \ 'revision': '',
        \ 'relpath': '',
        \}, get(a:000, 0, {})
        \)
  let params = filter(copy(options.params), '!empty(v:val)')
  let revision = substitute(options.revision, '^:0$', '', '')
  return s:normalize_bufname(printf(
        \ 'gina://%s:%s%s/%s:%s',
        \ a:git.refname,
        \ a:scheme,
        \ empty(params) ? '' : ':' . join(params, ':'),
        \ revision,
        \ s:Path.unixpath(options.relpath),
        \))
endfunction

function! gina#core#buffer#parse(expr) abort
  let path = expand(a:expr)
  let m = matchlist(
        \ path,'\v^gina://([^:]+):([^:\/]+)([^\/]*)[\/]?(:[0-3]|[^:]*):?(.*)$',
        \)
  if empty(m)
    return {}
  endif
  return {
        \ 'repo': m[1],
        \ 'scheme': m[2],
        \ 'params': filter(split(m[3], ':'), '!empty(v:val)'),
        \ 'revision': substitute(m[4], '^:0$', '', ''),
        \ 'relpath': m[5],
        \}
endfunction

function! gina#core#buffer#param(expr, attr, ...) abort
  if !has_key(s:DEFAULT_PARAMS_ATTRIBUTES, a:attr)
    throw gina#core#exception#critical(printf(
          \ 'Unknown attribute "%s" has specified',
          \ a:attr,
          \))
  endif
  let default = get(a:000, 0, s:DEFAULT_PARAMS_ATTRIBUTES[a:attr])
  let params = gina#core#buffer#parse(a:expr)
  return get(params, a:attr, default)
endfunction

function! gina#core#buffer#open(bufname, ...) abort
  let options = extend({
        \ 'mods': '',
        \ 'group': '',
        \ 'opener': '',
        \ 'cmdarg': '',
        \ 'line': v:null,
        \ 'col': v:null,
        \ 'callback': v:null,
        \}, get(a:000, 0, {}),
        \)
  let bufname = s:normalize_bufname(a:bufname)
  " Move focus to an anchor buffer if necessary
  if !s:Anchor.is_suitable(winnr())
    call s:Anchor.focus_if_available(options.opener)
  endif
  " Open a buffer
  if options.callback is# v:null
    let context = s:open_without_callback(bufname, options)
  else
    let context = s:open_with_callback(bufname, options)
  endif
  " Move cursor if necessary
  call setpos('.', [
        \ 0,
        \ options.line is# v:null ? line('.') : options.line,
        \ options.col is# v:null ? col('.') : options.col,
        \ 0,
        \])
  normal! zvzz
  " Finalize
  call context.end()
  return context
endfunction

function! gina#core#buffer#focus(expr) abort
  return s:Window.focus_buffer(a:expr)
endfunction

function! gina#core#buffer#assign_content(content) abort
  let options = s:Buffer.parse_cmdarg()
  let options.lockmarks = 1
  silent call s:Buffer.edit_content(a:content, options)
endfunction

function! gina#core#buffer#extend_content(content) abort
  let leading = getline('$')
  let content = [leading . get(a:content, 0, '')] + a:content[1:]
  let options = s:Buffer.parse_cmdarg()
  let options.edit = 1
  let options.line = '$'
  let options.lockmarks = 1
  silent lockmarks keepjumps $delete _
  silent call s:Buffer.read_content(content, options)
  if empty(getline(1))
    silent lockmarks keepjumps 1delete _
  endif
endfunction


" Private --------------------------------------------------------------------
function! s:focus(winnr) abort
  silent keepjumps keepalt execute printf('%dwincmd w', a:winnr)
endfunction

function! s:normalize_bufname(bufname) abort
  " The {bufname}
  " 1. Could not be started/ended with whitespaces
  " 2. Could not ends with ':' in Windows
  " 3. Should not ends with '/' in Vim 8 (opening a buffer fail randomly)
  let oldname = ''
  let newname = a:bufname
  while oldname !=# newname
    let oldname = newname
    let newname = substitute(newname, '\%(^\s\+\|\s\+$\)', '', 'g')
    let newname = substitute(newname, '\:\+$', '', '')
    let newname = substitute(newname, '[\\/]$', '', '')
  endwhile
  return newname
endfunction

function! s:open_without_callback(bufname, options) abort
  let context = s:Opener.open(a:bufname, {
        \ 'mods': a:options.mods,
        \ 'cmdarg': a:options.cmdarg,
        \ 'group':  a:options.group,
        \ 'opener': a:options.opener,
        \})
  return context
endfunction

function! s:open_with_callback(bufname, options) abort
  " Open a buffer without BufReadCmd
  let guard = s:Guard.store(['&eventignore'])
  try
    set eventignore+=BufReadCmd
    let context = s:Opener.open(a:bufname, {
          \ 'mods': a:options.mods,
          \ 'group':  a:options.group,
          \ 'opener': a:options.opener,
          \})
  finally
    call guard.restore()
  endtry
  " NOTE:
  " The content of the buffer MUST NOT be modified by callback while 'edit'
  " command will be called to override the content later.
  let content = getline(1, '$')
  call call(
        \ a:options.callback.fn,
        \ get(a:options.callback, 'args', []),
        \ a:options.callback
        \)
  if content != getline(1, '$')
    throw s:Exception.critical(
          \ 'A buffer content could not be modified by callback'
          \)
  endif
  " Update content
  if !&modified
    execute 'edit' a:options.cmdarg
  endif
  return context
endfunction
