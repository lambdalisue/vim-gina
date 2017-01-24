if exists('g:gina_loaded')
  finish
endif
let g:gina_loaded = 1

command! -nargs=* -range -bang
      \ -complete=customlist,gina#command#complete
      \ Gina
      \ call gina#command#call(<q-bang>, [<line1>, <line2>], <q-args>, <q-mods>)
