let s:Selection = vital#gina#import('Vim.Buffer.Selection')


function! gina#util#selection#format(...) abort
  return call(s:Selection.format_selection, a:000, s:Selection)
endfunction

function! gina#util#selection#parse(...) abort
  return call(s:Selection.parse_selection, a:000, s:Selection)
endfunction

function! gina#util#selection#set(...) abort
  return call(s:Selection.set_current_selection, a:000, s:Selection)
endfunction

function! gina#util#selection#get(...) abort
  return call(s:Selection.get_current_selection, a:000, s:Selection)
endfunction

function! gina#util#selection#from(bufname, selection) abort
  if !empty(a:selection)
    " Selection has specified so use it
    let selection = s:Selection.parse_selection(a:selection)
  elseif gina#util#expand(a:bufname) ==# gina#util#expand('%')
    " Going to open an alternative buffer of the current buffer
    " so use current selection
    let selection = s:Selection.get_current_selection()
  else
    let selection = []
  endif
  return selection
endfunction
