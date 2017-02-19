function! s:get(...) abort
  let name = a:0 ? a:1 : ''
  let records = split(s:_highlight(name), '\r\?\n')
  let highlights = map(records, 's:_parse_record(v:val)')
  let highlights = filter(highlights, '!empty(v:val)')
  return a:0 ? highlights[0] : highlights
endfunction

function! s:set(highlight, ...) abort
  let options = extend({
        \ 'force': 0,
        \ 'default': 0,
        \}, get(a:000, 0, {})
        \)
  let name = a:highlight.name
  let force = options.force ? '!' : ''
  let default = options.default ? 'default' : ''
  if get(a:highlight.attrs, 'clear')
    execute 'highlight' 'clear' name
  elseif !empty(get(a:highlight.attrs, 'link'))
    execute 'highlight' . force default 'link' name a:highlight.attrs.link
  else
    let attrs = map(items(a:highlight.attrs), 'v:val[0] . ''='' . v:val[1]')
    execute 'highlight' default name join(attrs)
  endif
endfunction


function! s:_parse_record(record) abort
  let m = matchlist(a:record, '^\(\S\+\)\s*xxx\s\(.*\)$')
  if empty(m)
    return {}
  endif
  let name = m[1]
  let attrs = s:_parse_attrs(m[2])
  return {'name': name, 'attrs': attrs}
endfunction

function! s:_parse_attrs(attrs) abort
  if a:attrs ==# 'cleared'
    return { 'cleared': 1 }
  elseif a:attrs =~# '^links to'
    return { 'link': matchstr(a:attrs, 'links to \zs.*') }
  endif
  let attrs = {}
  for term in split(a:attrs, ' ')
    let [key, val] = split(term, '=')
    let attrs[key] = val
  endfor
  return attrs
endfunction

if !has('nvim') || has('nvim-0.2.0')
  function! s:_highlight(name) abort
    return execute(printf('highlight %s', a:name))
  endfunction
else
  " Neovim 0.1.7 has 'execute()' but it seems the result of
  " execute('highlight') is squashd and cannot be parsed.
  function! s:_highlight(name) abort
    redir => content
    try
      execute 'highlight' a:name
    finally
      redir END
    endtry
    return content
  endfunction
endif
