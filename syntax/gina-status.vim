if exists('b:current_syntax')
  finish
endif

syntax match GinaStatusStaged /^[ MADRC] .*$/
syntax match GinaStatusUnstaged /^ [MDAU?] .*$/
syntax match GinaStatusPatched /^[MADRC][MDAU?] .*$/
syntax match GinaStatusIgnored /^!! .*$/
syntax match GinaStatusUntracked /^?? .*$/
syntax match GinaStatusConflicted /^\%(DD\|AU\|UD\|UA\|DU\|AA\|UU\) .*$/


function! s:define_highlights() abort
  highlight default link GinaStatusConflicted Error
  highlight default link GinaStatusStaged     Special
  highlight default link GinaStatusUnstaged   Comment
  highlight default link GinaStatusPatched    Constant
  highlight default link GinaStatusUntracked  GinaUnstaged
  highlight default link GinaStatusIgnored    Identifier
endfunction

augroup gina_syntax_status_internal
  autocmd! *
  autocmd ColorScheme * call s:define_highlights()
augroup END

call s:define_highlights()

let b:current_syntax = 'gina-status'
