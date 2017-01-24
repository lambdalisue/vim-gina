let s:Cache = vital#gina#import('System.Cache.Memory')
let s:Console = vital#gina#import('Vim.Console')
let s:Path = vital#gina#import('System.Filepath')


function! gina#router#load_modules(category) abort
  let cache = s:get_cache()
  if cache.has(a:category)
    return cache.get(a:category)
  endif
  call cache.set(a:category, s:load_modules(a:category))
  return cache.get(a:category)
endfunction

function! gina#router#clear_modules(category) abort
  let cache = s:get_cache()
  call cache.remove(a:category)
endfunction


" Private --------------------------------------------------------------------
function! s:get_cache() abort
  if exists('s:cache')
    return s:cache
  endif
  let s:cache = s:Cache.new()
  return s:cache
endfunction

function! s:load_modules(category) abort
  let suffix = s:Path.realpath(printf('autoload/gina/%s/*.vim', a:category))
  let modules = {}
  for runtimepath in split(&runtimepath, ',')
    let module_names = map(
          \ glob(s:Path.join(runtimepath, suffix), 0, 1),
          \ 'matchstr(fnamemodify(v:val, '':t''), ''^.\+\ze\.vim$'')',
          \)
    for module_name in module_names
      let modules[module_name] = s:load_module(a:category, module_name)
    endfor
  endfor
  return filter(modules, 'v:val isnot# v:null')
endfunction

function! s:load_module(category, name) abort
  try
    return call(printf('gina#%s#%s#define', a:category, a:name), [])
  catch /^Vim\%((\a\+)\)\=:E117: [^:]\+: gina#.*#define/
    call s:Console.debug(v:exception)
    call s:Console.debug(v:throwpoint)
  endtry
  return v:null
endfunction
