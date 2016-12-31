let s:Config = vital#gina#import('Data.Dict.Config')


" Default variable -----------------------------------------------------------
call s:Config.define('gina', {
      \ 'test': 0,
      \ 'debug': -1,
      \ 'develop': 1,
      \ 'complete_threshold': 30,
      \})
