function! gina#command#_raw#call(range, args, mods) abort
  let git = gina#core#get()
  let args = gina#command#parse_args(matchstr(a:args, '^_raw\s\+\zs.*'))
  let pipe = gina#process#pipe#echo()
  return gina#process#open(git, args, pipe)
endfunction

function! gina#command#_raw#complete(arglead, cmdline, cursorpos) abort
  return gina#complete#filename#any(a:arglead, a:cmdline, a:cursorpos)
endfunction
