if exists('b:current_syntax')
  finish
endif

syntax match GinaStatusStaged /^[ MADRC] .*$/
syntax match GinaStatusUnstaged /^ [MDAU?] .*$/
syntax match GinaStatusPatched /^[MADRC][MDAU?] .*$/
syntax match GinaStatusIgnored /^!! .*$/
syntax match GinaStatusUntracked /^?? .*$/
syntax match GinaStatusConflicted /^\%(DD\|AU\|UD\|UA\|DU\|AA\|UU\) .*$/

highlight default link GinaStatusConflicted Error
highlight default link GinaStatusStaged     Special
highlight default link GinaStatusUnstaged   Comment
highlight default link GinaStatusPatched    Constant
highlight default link GinaStatusUntracked  GinaUnstaged
highlight default link GinaStatusIgnored    Identifier

let b:current_syntax = 'gina-status'
