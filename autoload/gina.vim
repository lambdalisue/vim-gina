let s:Config = vital#gina#import('Config')


" Default variable -----------------------------------------------------------
call s:Config.define('gina', {
      \ 'test': 0,
      \ 'debug': -1,
      \ 'develop': 1,
      \ 'complete_threshold': 30,
      \})
