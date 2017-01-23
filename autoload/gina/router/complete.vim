let s:Exception = vital#gina#import('Vim.Exception')


function! gina#router#complete#call(arglead, cmdline, cursorpos) abort
  if a:cmdline =~# printf('^Gina %s$', a:arglead)
    let commands = gina#router#command#list()
    return filter(keys(commands), 'v:val =~# ''^'' . a:arglead')
  endif
  let cmdline = matchstr(a:cmdline, '^Gina \zs.*')
  let command = gina#router#command#get(matchstr(cmdline, '^\S\+'))
  if command is# v:null || !has_key(command, 'complete')
    return gina#complete#filename#any(a:arglead, cmdline, a:cursorpos)
  endif
  return s:Exception.call(
        \ command.complete,
        \ [a:arglead, cmdline, a:cursorpos],
        \ command
        \)
endfunction
