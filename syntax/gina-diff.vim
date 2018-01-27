if exists('b:current_syntax')
  finish
endif

" Use Vim's builtin syntax for diff
runtime! syntax/diff.vim

let b:current_syntax = 'gina-diff'
