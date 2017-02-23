let s:SCHEME = gina#command#scheme(expand('<sfile>'))


function! gina#command#lcd#call(range, args, mods) abort
  let args = a:args.clone()
  let args.set('--local', 1)
  call gina#command#cd#call(a:range, args, a:mods)
endfunction
