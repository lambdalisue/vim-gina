if exists('g:gina_loaded')
  finish
endif
let g:gina_loaded = 1

command! -nargs=* -range -bang -bar
      \ -complete=customlist,gina#router#complete
      \ Gina
      \ call gina#router#command(
      \   <q-bang>,
      \   [<line1>, <line2>],
      \   <q-args>,
      \   has('nvim') ? '' : <q-mods>
      \ )

augroup gina_internal
  autocmd! *
  autocmd BufReadCmd gina://* nested call gina#router#autocmd('BufReadCmd')
augroup END
