let s:preferences = {}

function! gina#custom#action#preference(scheme, ...) abort
  let readonly = a:0 ? a:1 : 1
  let s:preferences[a:scheme] = get(s:preferences, a:scheme, {})
  let preference = extend(s:preferences[a:scheme], {
        \ 'aliases': [],
        \ 'shortens': [],
        \}, 'keep'
        \)
  return readonly ? deepcopy(preference) : preference
endfunction

function! gina#custom#action#alias(scheme, alias, origin) abort
  let preference = gina#custom#action#preference(a:scheme, 0)
  call add(preference.aliases, [a:alias, a:origin])
endfunction

function! gina#custom#action#shorten(scheme, root, ...) abort
  let excludes = get(a:000, 0, [])
  let preference = gina#custom#action#preference(a:scheme, 0)
  call add(preference.shortens, [a:root, excludes])
endfunction


" Private --------------------------------------------------------------------
function! s:FileType() abort
  let scheme = gina#core#buffer#param('%', 'scheme')
  if empty(scheme)
    return
  endif
  let preference = gina#custom#action#preference(scheme)
  for [alias, origin] in preference.aliases
    call gina#action#alias(alias, origin)
  endfor
  for [root, excludes] in preference.shortens
    call gina#action#shorten(root, excludes)
  endfor
endfunction


" Autocmd --------------------------------------------------------------------
augroup gina_custom_action_internal
  autocmd! *
  autocmd FileType gina-* call s:FileType()
augroup END
