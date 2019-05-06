gina
==============================================================================
[![Gitter](https://img.shields.io/gitter/room/lambdalisue/gina-vim.svg?style=flat-square)](https://gitter.im/gina-vim)
[![Codecov](https://img.shields.io/codecov/c/github/lambdalisue/gina.vim/master.svg?style=flat-square)](https://codecov.io/gh/lambdalisue/gina.vim)
[![Travis CI](https://img.shields.io/travis/lambdalisue/gina.vim/master.svg?style=flat-square&label=Travis%20CI)](https://travis-ci.org/lambdalisue/gina.vim)
[![AppVeyor](https://img.shields.io/appveyor/ci/lambdalisue/gina-vim/master.svg?style=flat-square&label=AppVeyor)](https://ci.appveyor.com/project/lambdalisue/gina-vim/branch/master)
![Version 1.0.0](https://img.shields.io/badge/version-1.0.0-yellow.svg?style=flat-square)
![Support Vim 8.0.0107 or above](https://img.shields.io/badge/support-Vim%208.0.0107%20or%20above-yellowgreen.svg?style=flat-square)
![Support Neovim 0.2.0 or above](https://img.shields.io/badge/support-Neovim%200.2.0%20or%20above-yellowgreen.svg?style=flat-square)
![Support Git 1.8.5.6 or above](https://img.shields.io/badge/support-Git%201.8.5.6%20or%20above-green.svg?style=flat-square)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Doc](https://img.shields.io/badge/doc-%3Ah%20gina-orange.svg?style=flat-square)](doc/gina.txt)
[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg?style=flat-square)](https://github.com/vim-jp/vital.vim)

gina.vim (gina) is a plugin to asynchronously control git repositories.

The plugin was developed based on the success of [lambdalisue/vim-gita][].
So gina.vim has most of the outstanding features of vim-gita and drops some unwilling points.

**gina.vim is in beta-phase, mean that the features were not completed yet and the features may be modified without backward compatibility**

Presentation
-------------------------------------------------------------------------------
[![You've been Super Viman. After this talk, you could say you are Super Viman 2 -- Life with gina.vim](https://img.youtube.com/vi/zkANQ9l7YDM/0.jpg)](https://www.youtube.com/watch?v=zkANQ9l7YDM)

I've talked about what the gina.vim is in [VimConf2017](http://vimconf.vim-jp.org/2017/) ([Slide](https://lambdalisue.github.io/vimconf2017/assets/player/KeynoteDHTMLPlayer.html)). Check it out if you would like to feel what the gina.vim is.

Supports
-------------------------------------------------------------------------------
- Git 1.8.5.6 or above
- Vim 8.0.0107 or above or Neovim 0.2.0
- All major platforms
  - Linux (Tested on TravisCI, author use Linux)
  - macOS (Tested on TravisCI, author use OS X Elcapitan)
  - Windows (Tested on AppVeyor, main contributor use Windows)

Usage
-------------------------------------------------------------------------------

The following is a schematic image of general working-flow with gina.

```
   ┌─────┬──────────┐
   │     │          │
#DIRTY#  │          ▼
   ▲     │    :Gina status  │ <<  : stage
   │     │          │       │ >>  : unstage
   │     │          │       │ --  : toggle
:write   │       #STAGED#   │ ==  : discard
   ▲     │          │       │ pp  : patch
   │     ├──────────┤       │ dd  : diff
   │     │          ▼   
#CLEAN#  │     :Gina commit │ !   : switch --amend
   │     │          │       │ :w  : save cache
   │     ▼          │       │ :q  : commit changes (confirm)
   └────────────────┘       │ :wq : commit changes (immediate)
```

So basically user would

1. Edit contents in a git repository
2. Stage changes with `:Gina status`
3. Commit changes with `:Gina commit`

See `:h gina-usage` for advance usage. Gina provides a lot more features.

Pros.
-------------------------------------------------------------------------------

- A git detection is fast and accurate
  - It does not require `git` process so incredibly fast
  - Used in [lambdalisue/vim-gita][], for several years
- Commands are asynchronously performed
  - Users don't have to wait `:Gina push` (`git push`)
  - Asynchronous feature in Neovim is great. `:Gina log` (`git log`) on **Linux** repository won't freeze Neovim
- Single command. Users do not need to remember tons of commands
  - `:Gina {command}` will execute a gina command or a git raw command asynchronously
  - `:Gina! {command}` will execute a git raw command asynchronously
  - `:Gina!! {command}` will execute a git raw command in a shell (mainly for `:Gina!! add -p` or `:Gina!! rebase -i`)
- Action based. Users do not need to remember tons of mappings
  - `?` to see the help
  - `a` to select an action to perform (complete with `<Tab>`)
  - `.` to repeat previous action
  - All action can map to an actual keymap
- Author tried to follow Vim's flavor
  - No mapping for `ee` or whatever which conflicts with Vim's native mappings (like vim-gita does...)
- Customizable
  - Users can define action aliases and mappings
  - Users can define default options and aliases of command
  - More
- Tested on all major platforms
  - Powered by [vim-jp/vital.vim][], mean that the things are unit tested
  - Gina add some behaviour test as well

[lambdalisue/vim-gita]: https://github.com/lambdalisue/vim-gita
[vim-jp/vital.vim]:     https://github.com/vim-jp/vital.vim


Contribution
-------------------------------------------------------------------------------
Any contribution including documentations are welcome.

Contributers should install [thinca/vim-themis][] to run tests before sending a PR if they applied some modification to the code.
PRs which does not pass tests won't be accepted.

[thinca/vim-themis]: https://github.com/thinca/vim-themis


License
-------------------------------------------------------------------------------
The code in gina.vim follows MIT license texted in [LICENSE](./LICENSE).
Contributors need to agree that any modifications sent in this repository follow the license.
