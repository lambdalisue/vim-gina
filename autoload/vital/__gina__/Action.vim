let s:t_funcref = type(function('tr'))

let s:PREFIX = '_vital_action_binder_'
let s:UNIQUE = sha256(expand('<sfile>:p'))


function! s:_vital_loaded(V) abort
  let s:Exception = a:V.import('Vim.Exception')
endfunction

function! s:_vital_depends() abort
  return ['Vim.Exception']
endfunction

function! s:_vital_created(module) abort
  let a:module.name = 'action'
endfunction


function! s:get() abort
  return get(b:, s:PREFIX . s:UNIQUE, v:null)
endfunction

function! s:attach(...) abort dict
  let binder = extend(copy(s:binder), {
        \ 'name': substitute(self.name, '\W', '-', 'g'),
        \ '_candidates': get(a:000, 0, v:null),
        \ 'actions': {},
        \ 'aliases': {},
        \})
  " Lock methods
  lockvar binder.candidates
  lockvar binder.define
  lockvar binder.alias
  lockvar binder.action
  lockvar binder.call
  " Define builtin actions
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
  execute printf('nmap <buffer> ?     <Plug>(%s-builtin-help)', binder.name)
  execute printf('nmap <buffer> <Tab> <Plug>(%s-builtin-choice)', binder.name)
  execute printf('vmap <buffer> <Tab> <Plug>(%s-builtin-choice)', binder.name)
  execute printf('imap <buffer> <Tab> <Plug>(%s-builtin-choice)', binder.name)
  execute printf('nmap <buffer> . <Plug>(%s-builtin-repeat)', binder.name)
  execute printf('vmap <buffer> . <Plug>(%s-builtin-repeat)', binder.name)
  execute printf('imap <buffer> . <Plug>(%s-builtin-repeat)', binder.name)
  let b:{s:PREFIX . s:UNIQUE} = binder
  return binder
endfunction


" Instance -------------------------------------------------------------------
let s:binder = {}

function! s:binder.candidates(...) abort
  let fline = get(a:000, 0, line('.'))
  let lline = get(a:000, 1, fline)
  if self._candidates is v:null
    return getline(fline, lline)
  elseif type(self._candidates) == s:t_funcref
    return self._candidates(fline, lline)
  else
    return self._candidates[fline : lline]
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
        \ 'hidden': 0,
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
          \ '%snoremap <buffer><silent> %s %s:%scall <SID>_call_for_mapping(''%s'')<CR>',
          \ mode,
          \ action.mapping,
          \ mode =~# '[i]' ? '<Esc>' : '',
          \ mode =~# '[ni]' ? '<C-u>' : '',
          \ a:name,
          \)
  endfor
  let self.actions[action.name] = action
endfunction

function! s:binder.alias(alias, expr, ...) abort
  let alias = extend({
        \ 'name': matchstr(a:expr, '\S\+$'),
        \ 'expr': a:expr,
        \ 'alias': a:alias,
        \ 'mapping_mode': '',
        \}, get(a:000, 0, {}),
        \)
  let self.aliases[a:alias] = alias
endfunction

function! s:binder.action(expr) abort
  let mods = matchstr(a:expr, '^\%(.* \)\?\ze\S\+$')
  let name = matchstr(a:expr, '\S\+$')
  if has_key(self.aliases, name)
    let alias = self.aliases[name]
    return self.action(mods . alias.expr)
  elseif has_key(self.actions, name)
    return [mods, self.actions[name]]
  endif
  " If only one action/alias could be determine, use it.
  let candidates = filter(
        \ keys(self.aliases) + keys(self.actions),
        \ 'v:val =~# ''^'' . name'
        \)
  if len(candidates) == 1
    return self.action(mods . candidates[0])
  endif
  " None or More than one action/alias has detected
  if empty(candidates)
    throw s:Exception.warn(printf(
          \ 'No corresponding action has found for "%s"',
          \ a:expr
          \))
  else
    throw s:Exception.warn(printf(
          \ 'More than one action/alias has found for "%s"',
          \ a:expr
          \))
  endif
endfunction

function! s:binder.call(expr, ...) abort range
  let [mods, action] = self.action(a:expr)
  let candidates = copy(a:0 ? a:1 : self.candidates())
  if !empty(action.requirements)
    call filter(
          \ candidates,
          \ 's:_is_satisfied(v:val, action.requirements)',
          \)
    if empty(candidates)
      return
    endif
  endif
  let options = extend({
        \ 'mods': mods,
        \}, action.options
        \)
  call call(action.callback, [candidates, options], self)
  return action
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
    let alias = s:_find_alias(self, action)
    let identifier = empty(alias)
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

function! s:_compare_length(w1, w2) abort
  let l1 = len(a:w1)
  let l2 = len(a:w2)
  return l1 == l2 ? 0 : l1 > l2 ? 1 : -1
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

function! s:_find_alias(binder, action) abort
  let aliases = filter(
        \ values(a:binder.aliases),
        \ 'v:val.name ==# a:action.name',
        \)
  " Remove aliases with mods
  call filter(aliases, 'v:val.name ==# v:val.expr')
  " Prefer shorter name
  let candidates = sort(
        \ map(aliases, 'v:val.alias'),
        \ function('s:_compare_length')
        \)
  return get(candidates, 0, '')
endfunction

function! s:_complete_action_aliases(arglead, cmdline, cursorpos) abort
  let binder = s:_binder
  let actions = values(binder.actions)
  if empty(a:arglead)
    call filter(actions, '!v:val.hidden')
  endif
  let candidates = sort(extend(
        \ map(actions, 'v:val.name'),
        \ keys(binder.aliases),
        \))
  return filter(candidates, 'v:val =~# ''^'' . a:arglead')
endfunction

function! s:_call_for_mapping(name) abort range
  let binder = s:get()
  let candidates = binder.candidates(a:firstline, a:lastline)
  return s:Exception.call(binder.call, [a:name, candidates], binder)
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
