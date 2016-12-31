if exists('b:current_syntax')
  finish
endif

syntax match GinaStaged /^[ MADRC] .*$/
syntax match GinaUnstaged /^ [MDAU?] .*$/
syntax match GinaPatched /^[MADRC][MDAU?] .*$/
syntax match GinaIgnored /^!! .*$/
syntax match GinaUntracked /^?? .*$/
syntax match GinaConflicted /^\%(DD\|AU\|UD\|UA\|DU\|AA\|UU\) .*$/

highlight default link GinaConflicted Error
highlight default link GinaStaged     Special
highlight default link GinaUnstaged   Comment
highlight default link GinaPatched    Constant
highlight default link GinaUntracked  GinaUnstaged
highlight default link GinaIgnored    Identifier

let b:current_syntax = 'gina-status'
