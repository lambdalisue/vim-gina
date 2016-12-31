if exists('g:gina_loaded')
  finish
endif
let g:gina_loaded = 1

command! -nargs=* -range -bang -bar
      \ -complete=customlist,gina#command#complete
      \ Gina
      \ call gina#command#command(
      \   <q-bang>,
      \   [<line1>, <line2>],
      \   <q-args>,
      \   has('nvim') ? '' : <q-mods>
      \ )

augroup gina_internal
  autocmd! *
  autocmd BufReadCmd gina://* nested call gina#command#autocmd('BufReadCmd')
augroup END
