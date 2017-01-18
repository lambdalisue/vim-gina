let s:Anchor = vital#gina#import('Vim.Buffer.Anchor')
let s:Buffer = vital#gina#import('Vim.Buffer')
let s:Opener = vital#gina#import('Vim.Buffer.Opener')
let s:Guard = vital#gina#import('Vim.Guard')


function! gina#util#buffer#open(bufname, ...) abort
  let options = extend({
        \ 'group': '',
        \ 'opener': '',
        \ 'selection': v:null,
        \ 'callback': v:null,
        \}, get(a:000, 0, {}),
        \)
  " Move focus to an anchor buffer if necessary
  if !s:Anchor.is_suitable(winnr())
    call s:Anchor.focus_if_available(options.opener)
  endif
  " Open a buffer without BufReadCmd
  let guard = s:Guard.store(['&eventignore'])
  try
    set eventignore+=BufReadCmd
    silent let context = s:Opener.open(a:bufname, {
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
  if options.selection isnot v:null
    call gina#util#selection#set(options.selection)
  endif
  " Finalize
  call gina#command#ready_stream()
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
