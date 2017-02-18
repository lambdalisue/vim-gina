if exists('b:current_syntax')
  finish
endif

syntax match GinaEventsPrefix /^[^:]\+/
syntax match GinaEventsTime /\d\{2}:\d\{2}:\d\{2}\.\d\{6}/
syntax match GinaEventsComment /^| .*$/
syntax match GinaEventsComment /\[.\{-}\]$/

highlight default link GinaEventsComment Comment
highlight default link GinaEventsPrefix  Statement
highlight default link GinaEventsTime    Title

let b:current_syntax = 'gina-_events'
