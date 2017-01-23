if exists('g:gina_loaded')
  finish
endif
let g:gina_loaded = 1

command! -nargs=* -range -bang -bar
      \ -complete=customlist,gina#router#complete#call
      \ Gina
      \ call gina#router#command#call(<q-bang>, [<line1>, <line2>], <q-args>, <q-mods>)

augroup gina_internal
  autocmd! *
  autocmd BufReadCmd gina://* nested call gina#router#autocmd#call('BufReadCmd')
augroup END
