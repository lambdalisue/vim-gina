let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')
let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Guard = vital#gina#import('Vim.Guard')
let s:Opener = vital#gina#import('Vim.Buffer.Opener')
let s:Path = vital#gina#import('System.Filepath')


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
  let guard = copy(s:focus_guard)
  let bufnr = bufnr(a:expr)
  let winnr = bufwinnr(bufnr)
  if bufnr == 0 || winnr == 0
    return v:null
  endif
  if winnr() != winnr
    let guard.bufnum = bufnr('%')
    call s:focus(winnr)
  endif
  return guard
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
    let newname = s:Path.remove_last_separator(newname)
  endwhile
  return newname
endfunction

function! s:open_without_callback(bufname, options) abort
  let context = s:Opener.open(a:bufname, {
        \ 'mods': a:options.mods,
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
  call call(
        \ a:options.callback.fn,
        \ a:options.callback.args,
        \ a:options.callback
        \)
  " Update content
  execute 'edit' a:options.cmdarg
  return context
endfunction


" Focus guard ----------------------------------------------------------------
let s:focus_guard = {}

function! s:focus_guard.restore() abort
  let bufnr = get(self, 'bufnum', 0)
  if bufnr && bufexists(bufnr)
    call s:focus(bufwinnr(bufnr))
  endif
endfunction
