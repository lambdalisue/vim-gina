if exists('b:current_syntax')
  finish
endif
syntax match GinaBlameAdditional /^|.*/
syntax match GinaBlameHead /^\%(\w\{8}\|\w\{7}\^\|\^\w\{7}\|\$\w\{7}\)\s\+@.*$/
syntax match GinaBlameAuthor /@.*$/ containedin=GinaBlameHead
syntax match GinaBlameRevNormal /^\w\{8}/ containedin=GinaBlameHead
syntax match GinaBlameRevParent /^\w\{7}\^/ containedin=GinaBlameHead
syntax match GinaBlameRevBoundary /^\^\w\{7}/ containedin=GinaBlameHead
syntax match GinaBlameRevTerminal /^\$\w\{7}/ containedin=GinaBlameHead

function! s:define_highlights() abort
  highlight default link GinaBlameAdditional Comment
  highlight default link GinaBlameAuthor Statement
  highlight default link GinaBlameRevNormal Tag
  highlight default link GinaBlameRevParent Type
  highlight default link GinaBlameRevBoundary Constant
  highlight default link GinaBlameRevTerminal Constant
endfunction

augroup gina_syntax_blame_internal
  autocmd! * <buffer>
  autocmd ColorScheme * call s:define_highlights()
augroup END

call s:define_highlights()
let b:current_syntax = 'gina-blame'
