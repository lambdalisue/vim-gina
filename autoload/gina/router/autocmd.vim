let s:Console = vital#gina#import('Vim.Console')
let s:Exception = vital#gina#import('Vim.Exception')


function! gina#router#autocmd#call(name) abort
  let params = gina#util#params(expand('<afile>'))
  let command = gina#router#command#get(params.scheme)
  if command is# v:null
    return s:Console.error(printf(
          \ 'No command module "%s" is defined.'),
          \ params.scheme,
          \)
  elseif !has_key(command, a:name)
    return s:Console.error(printf(
          \ 'A command module "%s" does not define an autocmd "%s".'),
          \ params.scheme, a:name,
          \)
  endif
  return s:Exception.call(command[a:name], [], command)
endfunction
