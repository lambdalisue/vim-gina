if exists('b:current_syntax')
  finish
endif

syntax match GinaAdded /^\d\+/ nextgroup=GinaRemoved skipwhite
syntax match GinaRemoved /\d\+/ nextgroup=GinaPath skipwhite contained
syntax match GinaPath /.\+/ contained

highlight default link GinaAdded   Statement
highlight default link GinaRemoved Constant
highlight default link GinaPath    Comment

let b:current_syntax = 'gina-changes'
