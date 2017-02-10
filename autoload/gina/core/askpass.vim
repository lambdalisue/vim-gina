let s:Config = vital#gina#import('Config')
let s:Console = vital#gina#import('Vim.Console')
let s:Path = vital#gina#import('System.Filepath')

let s:is_windows = has('win32') || has('win64')
let s:is_darwin = has('mac') || has('macunix')
let s:repository_root = expand('<sfile>:p:h:h:h:h')
let s:askpass_script = s:Path.join(s:repository_root, 'scripts', 'askpass')

if s:is_windows
  " win-ssh-askpass may help?
  " https://sourceforge.net/projects/winsshaskpass/
  let s:askpass_script = ''
elseif s:is_darwin
  " AFAI, no usable GUI ssh-askpass exist
  let s:askpass_script .= '.mac'
else
  if executable('zenity')
    let s:askpass_script .= '.zenity'
  else
    " ssh-askpass-gnome would help in this case
    let s:askpass_script = ''
  endif
endif

if s:is_windows
  function! gina#core#askpass#wrap(git, args) abort
    if empty($GIT_TERMINAL_PROMPT) && !g:gina#core#askpass#suppress_warning
      call s:Console.warn('$GIT_TERMINAL_PROMPT has not configured.')
      call s:Console.warn('The environment variable should be configured.')
      call s:Console.warn('See :h gina-askpass-windows')
    endif
    " NOTE:
    " Windows does not have 'env' like application so use '-c core.askpass'
    " instead of '$GIT_ASKPASS' environment variable
    let askpass = s:askpass(a:git)
    if !empty(askpass)
      call insert(a:args.raw, ['-c', 'core.askpass=' . askpass], 1)
    endif
    return a:args
  endfunction
else
  function! gina#core#askpass#wrap(git, args) abort
    let prefix = ['env', 'GIT_TERMINAL_PROMPT=0']
    let askpass = s:askpass(a:git)
    if !empty(askpass)
      " NOTE:
      " '$GIT_ASKPASS' has a higest priority so use this instead of
      " '-c core.askpass=...' in Mac/Linux environment while 'env'
      " is available.
      let prefix += ['GIT_ASKPASS=' . askpass]
    endif
    let a:args.raw = prefix + a:args.raw
    return a:args
  endfunction
endif


function! s:askpass(git) abort
  let config = gina#core#repo#config(a:git)
  let askpass = get(get(config, 'core', {}), 'askpass')
  if !empty(g:gina#core#askpass#askpass_program)
    return g:gina#core#askpas#askpass_program
  elseif g:gina#core#askpass#force_internal_script
    return s:askpass_script
  elseif exists('$GIT_ASKPASS')
    return $GIT_ASKPASS
  elseif !empty(askpass)
    return askpass
  elseif exists('$SSH_ASKPASS')
    return $SSH_ASKPASS
  endif
  return s:askpass_script
endfunction


call s:Config.define('g:gina#core#askpass', {
      \ 'askpass_program': '',
      \ 'force_internal_script': 0,
      \ 'suppress_warning': 1,
      \})
