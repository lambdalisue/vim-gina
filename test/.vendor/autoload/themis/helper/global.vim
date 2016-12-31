" Until: https://github.com/thinca/vim-themis/pull/42
let s:event = {
      \ 'globals': [],
      \}

function! s:event.start(runner) abort
  for global in self.globals
    if has_key(global, 'initialize')
      call global.initialize()
    endif
  endfor
endfunction

function! s:event.before_suite(bundle) abort
  for global in self.globals
    if has_key(global, 'before')
      call global.before()
    endif
  endfor
endfunction

function! s:event.before_test(bundle, entry) abort
  for global in self.globals
    if has_key(global, 'before_each')
      call global.before_each()
    endif
  endfor
endfunction

function! s:event.end(runner) abort
  for global in self.globals
    if has_key(global, 'finalize')
      call global.finalize()
    endif
  endfor
endfunction

function! s:event.after_suite(bundle) abort
  for global in self.globals
    if has_key(global, 'after')
      call global.after()
    endif
  endfor
endfunction

function! s:event.after_test(bundle, entry) abort
  for global in self.globals
    if has_key(global, 'after_each')
      call global.after_each()
    endif
  endfor
endfunction


let s:helper = {
      \ 'event': s:event,
      \}

function! s:helper.with(globals) abort
  let globals = type(a:globals) == 3 ? a:globals : [a:globals]
  call extend(self.event.globals, globals)
  return self
endfunction


function! themis#helper#global#new(runner) abort
  let helper = deepcopy(s:helper)
  call a:runner.add_event(helper.event)
  return helper
endfunction
