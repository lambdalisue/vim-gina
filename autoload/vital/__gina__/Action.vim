function! s:_vital_loaded(V) abort
  let s:Exception = a:V.import('Vim.Exception')
  let s:PREFIX = '_vital_action_binder_'
  let s:t_funcref = type(function('tr'))
endfunction

function! s:_vital_depends() abort
  return ['Vim.Exception']
endfunction

function! s:attach(name, ...) abort
  let binder = extend(copy(s:binder), {
        \ 'name': a:name,
        \ 'candidates': get(a:000, 0, v:null),
        \ 'actions': {},
        \ 'aliases': {},
        \})
  call binder.define('builtin:echo', function('s:_action_echo'), {
        \ 'hidden': 1,
        \ 'description': 'Echo the candidates',
        \})
  call binder.define('builtin:help', function('s:_action_help'), {
        \ 'description': 'Show help of actions',
        \ 'mapping_mode': 'n',
        \ 'repeatable': 0,
        \})
  call binder.define('builtin:help:all', function('s:_action_help'), {
        \ 'description': 'Show help of actions including hidden actions',
        \ 'mapping_mode': 'n',
        \ 'options': { 'all': 1 },
        \ 'repeatable': 0,
        \})
  call binder.define('builtin:choice', function('s:_action_choice'), {
        \ 'description': 'Select action to perform',
        \ 'mapping_mode': 'inv',
        \ 'repeatable': 0,
        \})
  call binder.define('builtin:repeat', function('s:_action_repeat'), {
        \ 'description': 'Repeat previous repeatable action',
        \ 'mapping_mode': 'inv',
        \ 'repeatable': 0,
        \})
  call binder.alias('echo', 'builtin:echo')
  call binder.alias('help', 'builtin:help')
  call binder.alias('help:all', 'builtin:help:all')
  let name = substitute(a:name, ':', '-', 'g')
  execute printf('nmap <buffer> ?     <Plug>(%s-builtin-help)', name)
  execute printf('nmap <buffer> <Tab> <Plug>(%s-builtin-choice)', name)
  execute printf('vmap <buffer> <Tab> <Plug>(%s-builtin-choice)', name)
  execute printf('imap <buffer> <Tab> <Plug>(%s-builtin-choice)', name)
  execute printf('nmap <buffer> . <Plug>(%s-builtin-repeat)', name)
  execute printf('vmap <buffer> . <Plug>(%s-builtin-repeat)gv', name)
  execute printf('imap <buffer> . <Plug>(%s-builtin-repeat)', name)
  let b:{s:PREFIX . a:name} = binder
  return binder
endfunction

function! s:get(name) abort
  return get(b:, s:PREFIX . a:name, v:null)
endfunction


" Instance -------------------------------------------------------------------
let s:binder = {}

function! s:binder.get_alias(name) abort
  for [alias, name] in items(self.aliases)
    if name ==# a:name
      return alias
    endif
  endfor
  return a:name
endfunction

function! s:binder.get_action(name) abort
  if has_key(self.actions, a:name)
    return self.actions[a:name]
  elseif has_key(self.aliases, a:name)
    return self.actions[self.aliases[a:name]]
  endif
  " Try to find most similar action
  let aliases = filter(keys(self.aliases), 'v:val =~# ''^'' . a:name')
  let actions = extend(
        \ filter(keys(self.actions), 'v:val =~# ''^'' . a:name'),
        \ map(aliases, 'self.aliases[v:val]')
        \)
  if empty(actions)
    throw s:Exception.warn(
          \ printf('No action "%s" is found', a:name)
          \)
  endif
  let actions = sort(
        \ map(actions, 'self.actions[v:val]'),
        \ 's:_compare_action_priority'
        \)
  return get(actions, 0)
endfunction

function! s:binder.get_candidates(fline, lline) abort
  if self.candidates is v:null
    return getline(a:fline, a:lline)
  elseif type(self.candidates) == s:t_funcref
    return self.candidates(a:fline, a:lline)
  else
    return self.candidates[a:fline : a:lline]
  endif
endfunction

function! s:binder.define(name, callback, ...) abort
  let action = extend({
        \ 'callback': a:callback,
        \ 'name': a:name,
        \ 'description': '',
        \ 'mapping': '',
        \ 'mapping_mode': '',
        \ 'requirements': [],
        \ 'options': {},
        \ 'default': 0,
        \ 'hidden': 0,
        \ 'priority': 0,
        \ 'repeatable': 1,
        \}, get(a:000, 0, {}),
        \)
  if empty(action.mapping)
    let action.mapping = printf(
          \ '<Plug>(%s-%s)',
          \ substitute(self.name, '\W', '-', 'g'),
          \ substitute(action.name, '\W', '-', 'g'),
          \)
  endif
  for mode in split(action.mapping_mode, '\zs')
    execute printf(
          \ '%snoremap <buffer><silent> %s %s:%scall <SID>_call_for_mapping(''%s'', ''%s'')<CR>',
          \ mode,
          \ action.mapping,
          \ mode =~# '[i]' ? '<Esc>' : '',
          \ mode =~# '[ni]' ? '<C-u>' : '',
          \ self.name,
          \ a:name,
          \)
  endfor
  let self.actions[action.name] = action
endfunction

function! s:binder.alias(alias, name) abort
  let action = self.get_action(a:name)
  let self.aliases[a:alias] = action.name
endfunction

function! s:binder.call(name_or_alias, candidates) abort range
  let action = self.get_action(a:name_or_alias)
  let candidates = copy(a:candidates)
  if !empty(action.requirements)
    let candidates = filter(
          \ candidates,
          \ 's:_is_satisfied(v:val, action.requirements)',
          \)
    if empty(candidates)
      return
    endif
  endif
  call s:Exception.call(action.callback, [candidates, action.options], self)
  return action
endfunction

function! s:binder.smart_map(mode, lhs, rhs, ...) abort
  let lhs = get(a:000, 0, a:lhs)
  for mode in split(a:mode, '\zs')
    execute printf(
          \ '%smap <buffer><expr> %s <SID>_smart_map(''%s'', ''%s'', ''%s'')',
          \ mode, a:lhs, self.name, lhs, a:rhs,
          \)
  endfor
endfunction


" Actions --------------------------------------------------------------------
function! s:_action_echo(candidates, options) abort
  for candidate in a:candidates
    echo string(candidate)
  endfor
endfunction

function! s:_action_help(candidates, options) abort dict
  let mappings = s:_find_mappings(self)
  let actions = values(self.actions)
  if !get(a:options, 'all')
    call filter(actions, '!v:val.hidden')
  endif
  let rows = []
  let longest1 = 0
  let longest2 = 0
  let longest3 = 0
  for action in actions
    let mapping = get(mappings, action.mapping, {})
    let lhs = !empty(action.mapping) && !empty(mapping) ? mapping.lhs : ''
    let alias = self.get_alias(action.name)
    let identifier = alias ==# action.name
          \ ? action.name
          \ : printf('%s [%s]', action.name, alias)
    let hidden = action.hidden ? '*' : ' '
    let description = action.description
    let mapping = printf('%s [%s]', action.mapping, action.mapping_mode)
    call add(rows, [
          \ lhs,
          \ identifier,
          \ hidden,
          \ description,
          \ mapping,
          \])
    let longest1 = len(lhs) > longest1 ? len(lhs) : longest1
    let longest2 = len(identifier) > longest2 ? len(identifier) : longest2
    let longest3 = len(description) > longest3 ? len(description) : longest3
  endfor

  let content = []
  let pattern = printf(
        \ '%%-%ds  %%-%ds %%s %%-%ds  %%s',
        \ longest1,
        \ longest2,
        \ longest3,
        \)
  for params in sort(rows, 's:_compare')
    call add(content, call('printf', [pattern] + params))
  endfor
  echo join(content, "\n")
endfunction

function! s:_action_choice(candidates, options) abort dict
  let s:_binder = self
  call inputsave()
  try
    echohl Question
    redraw | echo
    let fname = s:_get_function_name(function('s:_complete_action_aliases'))
    let aname = input(
          \ 'action: ', '',
          \ printf('customlist,%s', fname),
          \)
    redraw | echo
  finally
    echohl None
    call inputrestore()
  endtry
  if empty(aname)
    return
  endif
  let action = self.call(aname, a:candidates)
  if action.repeatable
    let self.previous_action = action
  endif
endfunction

function! s:_action_repeat(candidates, options) abort dict
  let action = get(self, 'previous_action', {})
  if empty(action)
    return
  endif
  return self.call(action.name, a:candidates)
endfunction


" Privates -------------------------------------------------------------------
function! s:_is_satisfied(candidate, requirements) abort
  for requirement in a:requirements
    if !has_key(a:candidate, requirement)
      return 0
    endif
  endfor
  return 1
endfunction

function! s:_compare(i1, i2) abort
  return a:i1[1] == a:i2[1] ? 0 : a:i1[1] > a:i2[1] ? 1 : -1
endfunction

function! s:_compare_action_priority(i1, i2) abort
  if a:i1.priority == a:i2.priority
    return len(a:i1.name) - len(a:i2.name)
  else
    return a:i1.priority > a:i2.priority ? 1 : -1
  endif
endfunction

function! s:_find_mappings(binder) abort
  let content = s:_execute('map')
  let rhss = filter(
        \ map(values(a:binder.actions), 'v:val.mapping'),
        \ '!empty(v:val)'
        \)
  let rhsp = printf('\%%(%s\)', join(map(rhss, 'escape(v:val, ''\'')'), '\|'))
  let rows = filter(split(content, '\r\?\n'), 'v:val =~# ''@.*'' . rhsp')
  let pattern = '\(...\)\(\S\+\)'
  let mappings = {}
  for row in rows
    let [mode, lhs] = matchlist(row, pattern)[1 : 2]
    let rhs = matchstr(row, rhsp)
    let mappings[rhs] = {
          \ 'mode': mode,
          \ 'lhs': lhs,
          \ 'rhs': rhs,
          \}
  endfor
  return mappings
endfunction

function! s:_complete_action_aliases(arglead, cmdline, cursorpos) abort
  let binder = s:_binder
  let actions = values(binder.actions)
  if empty(a:arglead)
    call filter(actions, '!v:val.hidden')
  endif
  call sort(actions, 's:_compare_action_priority')
  return filter(map(actions, 'binder.get_alias(v:val.name)'), 'v:val =~# ''^'' . a:arglead')
endfunction

function! s:_smart_map(name, lhs, rhs) abort range
  let binder = s:get(a:name)
  try
    let candidates = binder.get_candidates(a:firstline, a:lastline)
    return empty(candidates) ? a:lhs : a:rhs
  catch
    return a:lhs
  endtry
endfunction

function! s:_call_for_mapping(name, action_name) abort range
  let binder = s:get(a:name)
  let candidates = binder.get_candidates(a:firstline, a:lastline)
  return call(binder.call, [a:action_name, candidates], binder)
endfunction


" Compatibility --------------------------------------------------------------
if has('patch-7.4.1842')
  function! s:_get_function_name(fn) abort
    return get(a:fn, 'name')
  endfunction
else
  function! s:_get_function_name(fn) abort
    return matchstr(string(a:fn), 'function(''\zs.*\ze''')
  endfunction
endif

if exists('*execute')
  let s:_execute = function('execute')
else
  function! s:_execute(command) abort
    try
      redir => content
      silent execute a:command
    finally
      redir END
    endtry
    return content
  endfunction
endif
