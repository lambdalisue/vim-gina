let s:Argument = vital#gina#import('Argument')

function! gina#core#args#raw(rargs) abort
  return s:Argument.new(a:rargs)
endfunction

function! gina#core#args#new(rargs) abort
  let args = gina#core#args#raw(a:rargs)
  for preference in gina#custom#preferences(args.get(0))
    " Assign default options
    for [query, value, remover] in preference.command.options
      if !empty(remover) && args.has(remover)
        call args.pop(remover)
        call args.pop(query)
      elseif !args.has(query)
        call args.set(query, value)
      endif
    endfor
    " Assign alias
    if preference.command.raw
      call args.set(0, ['_raw', preference.command.origin])
    else
      call args.set(0, preference.command.origin)
    endif
  endfor
  " Expand residuals to allow '%'
  let pathlist = args.residual()
  if !empty(pathlist)
    call args.residual(map(pathlist, 'gina#core#path#expand(v:val)'))
  endif
  " Assig global params
  let args.params = {}
  let args.params.scheme = args.get(0, '')
  let cmd = args.pop('^+')
  let cmdarg = []
  while !empty(cmd)
    call add(cmdarg, cmd)
    let cmd = args.pop('^+')
  endwhile
  let args.params.cmdarg = empty(cmdarg) ? '' : (join(cmdarg) . ' ')
  return args
endfunction

function! gina#core#args#extend_path(git, args, path) abort
  if a:path is# v:null
    let a:args.params.path = v:null
  else
    let path = empty(a:path)
          \ ? gina#core#path#expand('%')
          \ : gina#core#path#expand(a:path)
    let path = gina#core#repo#relpath(a:git, path)
    let a:args.params.path = path
  endif
endfunction

function! gina#core#args#extend_treeish(git, args, treeish) abort
  if a:treeish is# v:null
    let rev = v:null
    let path = v:null
  else
    let [rev, path] = gina#core#treeish#parse(a:treeish)
    " Guess a revision from the current buffer name if necessary
    if empty(rev)
      let rev = gina#core#buffer#param('%', 'rev')
    endif
    " Guess a path from the current buffer name if necessary
    " and make sure that the path is a relative path from rep root
    if path isnot# v:null
      let path = empty(path) ? gina#core#path#expand('%') : path
      let path = gina#core#repo#relpath(a:git, path)
    endif
  endif
  call extend(a:args.params, {
        \ 'rev': rev,
        \ 'path': path,
        \ 'treeish': gina#core#treeish#build(rev, path),
        \})
endfunction
