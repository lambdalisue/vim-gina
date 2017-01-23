let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')
let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Guard = vital#gina#import('Vim.Guard')
let s:Opener = vital#gina#import('Vim.Buffer.Opener')
let s:Path = vital#gina#import('System.Filepath')


function! gina#util#buffer#open(bufname, ...) abort
  let options = extend({
        \ 'group': '',
        \ 'opener': '',
        \ 'line': v:null,
        \ 'col': v:null,
        \ 'callback': v:null,
        \}, get(a:000, 0, {}),
        \)
  " The {bufname} could not be opened randomly in Vim 8 when the {bufname}
  " ends with a slash so remove the trailing one.
  let bufname = s:Path.remove_last_separator(a:bufname)
  " Move focus to an anchor buffer if necessary
  if !s:Anchor.is_suitable(winnr())
    call s:Anchor.focus_if_available(options.opener)
  endif
  " Open a buffer without BufReadCmd
  let guard = s:Guard.store(['&eventignore'])
  try
    set eventignore+=BufReadCmd
    silent let context = s:Opener.open(bufname, {
          \ 'group':  options.group,
          \ 'opener': options.opener,
          \})
  finally
    call guard.restore()
  endtry
  " Call callback if necessary
  if options.callback isnot v:null
    call call(
          \ options.callback.fn,
          \ options.callback.args,
          \ options.callback
          \)
  endif
  " Move cursor if necessary
  call setpos('.', [
        \ 0,
        \ options.line is# v:null ? line('.') : options.line,
        \ options.col is# v:null ? col('.') : options.col,
        \ 0,
        \])
  " Finalize
  call gina#util#doautocmd('BufReadCmd')
  call context.end()
  return context
endfunction

function! gina#util#buffer#focus(expr) abort
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

function! gina#util#buffer#content(...) abort
  lockmarks return call(s:Buffer.edit_content, a:000, s:Buffer)
endfunction


" Private --------------------------------------------------------------------
function! s:focus(winnr) abort
  silent keepjumps keepalt execute printf('%dwincmd w', a:winnr)
endfunction


" Focus guard ----------------------------------------------------------------
let s:focus_guard = {}

function! s:focus_guard.restore() abort
  let bufnr = get(self, 'bufnum', 0)
  if bufnr && bufexists(bufnr)
    call s:focus(bufwinnr(bufnr))
  endif
endfunction
