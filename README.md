gina
==============================================================================
[![Travis CI](https://img.shields.io/travis/lambdalisue/gina.vim/master.svg?style=flat-square&label=Travis%20CI)](https://travis-ci.org/lambdalisue/gina.vim)
[![AppVeyor](https://img.shields.io/appveyor/ci/lambdalisue/gina-vim/master.svg?style=flat-square&label=AppVeyor)](https://ci.appveyor.com/project/lambdalisue/gina-vim/branch/master)
![Version 0.1.0-dev](https://img.shields.io/badge/version-0.1.0--dev-yellow.svg?style=flat-square)
![Support Vim 8.0.0134 or above](https://img.shields.io/badge/support-Vim%208.0.0134%20or%20above-yellowgreen.svg?style=flat-square)
![Support Neovim 0.1.7 or above](https://img.shields.io/badge/support-Neovim%200.1.7%20or%20above-yellowgreen.svg?style=flat-square)
![Support Git 1.8.5.6 or above](https://img.shields.io/badge/support-Git%201.8.5.6%20or%20above-green.svg?style=flat-square)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE.md)
[![Doc](https://img.shields.io/badge/doc-%3Ah%20gina-orange.svg?style=flat-square)](doc/gina.txt)


**Under development..**
**You should checkout [lambdalisue/vim-gita](https://github.com/lambdalisue/vim-gita) if you need a stable one.**

gina.vim is a git manipulation plugin which use a job features of Vim 8 or Neovim.


Features
-------------------------------------------------------------------------------

**While gina.vim is in alpha state. The following features are not settle yet.**

- [x] Synchronous git command execution by `Gina[!] {command} {options}`
- [x] Asynchronous git command execution by `Gina[!] --async {command} {options}`
- [x] Gina actions
  - [x] Actions for branch manipulation
  - [x] Actions for browsing a remote content
  - [x] Actions for see changes
  - [x] Actions for commit
  - [x] Actions for comparing
  - [x] Actions for diff
  - [x] Actions for showing a content in a working tree
  - [x] Actions for exporting candidates to quickfix
  - [x] Actions for status manipulation
  - [x] Actions for patching
  - [x] Actions for showing a content in a particular commit
  - [ ] Actions for solving conflicts
  - [ ] Actions for tag manipulation
  - [ ] Actions for reflog
- [ ] Gina commands
  - [x] List branches by `Gina branch`
  - [x] Open a system browser to see the remote content by `Gina browse`
  - [ ] Blame a content by `Gina blame` (might goes to an external plugin)
  - [x] Change current working directory by `Gina cd` or `Gina lcd`
  - [x] List changes (files) between two particular commits by `Gina changes`
  - [x] Solve conflict by three-side diff by `Gina chaperon` (might goes to an external plugin)
  - [x] Open a commit buffer by `Gina commit`
  - [x] Compare changes by two-side diff by `Gina compare`
  - [x] Compare changes by one-side diff by `Gina diff`
  - [x] Show a content in the working tree by `Gina edit`
  - [x] Grep contents by `Gina grep`
  - [x] List commit logs of repository/file by `Gina log` or `Gina log -- {path}`
  - [x] List files in the working tree by `Gina ls-files`
  - [x] List files in a particular commit by `Gina ls-tree`
  - [x] Patch changes by three-side diff by `Gina patch`
  - [x] List reflogs by `Gina reflog`
  - [x] Show a content in a particular commit by `Gina show`
  - [x] Show a current working tree status by `Gina status`
  - [x] List tags by `Gina tag`
  - [ ] Create a new tag by `Gina tag -a` without `-m` or `-F` (Open a buffer like `Gina commit`)
- [ ] Command completions
- [ ] Statusline/Tabline components
- [x] `++enc` and `++ff` for command which open a window
- [x] Line/Column assignment for `Gina show` and `Gina edit`
- [x] Customization by `gina#command#custom({scheme}, {query}, {value})`
  For example:
  ```vim
  " Add '--verbose' option to 'commit' command if not specified
  call gina#command#custom('commit', '--verbose', 1)

  " Use 'botright 10split' instead of the default opener
  call gina#command#custom('status', '--opener', 'botright 10split')

  " Open up in different window
  call gina#command#custom('grep', '--group', 'grep-window')
  ```
- [x] Customization by `gina#action#alias({alias}, {action_name})`
  For example:
  ```vim
  " Use 'right' for 'edit:right'
  call gina#action#alias('right', 'edit:right')
  ```


Contribution
-------------------------------------------------------------------------------

**While gina.vim is in alpha state.
Changes you've made will removed without any announcement/permission.
PRs should NOT be sent without understanding this situation.**

gina.vim use [thinca/vim-themis](https://github.com/thinca/vim-themis) to run tests.
Contributers should install the plugin and test before sending a PR.
PRs which does not pass tests won't be accepted.


License
-------------------------------------------------------------------------------
The code in gina.vim follows MIT license texted in [LICENSE.md](./LICENSE.md).
Contributors need to agree that any modifications sent in this repository follow the license.

