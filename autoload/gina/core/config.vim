let s:Config = vital#gina#import('Config')
let s:Path = vital#gina#import('System.Filepath')


function! gina#core#config#define(sfile, options) abort
  return s:Config.define(s:translate(a:sfile), a:options)
endfunction


" Private --------------------------------------------------------------------
function! s:translate(sfile) abort
  let path = s:Path.unixpath(a:sfile)
  let name = matchstr(path, 'autoload/\zs\%(gina\.vim\|gina/.*\)$')
  let name = substitute(name, '\.vim$', '', '')
  let name = substitute(name, '/', '#', 'g')
  let name = substitute(name, '\%(^#\|#$\)', '', 'g')
  return 'g:' . name
endfunction
