let s:dein_dir = $XDG_CACHE_HOME. '/nvim/dein'
let s:dein_repo_dir = s:dein_dir. '/repos/github.com/Shougo/dein.vim'

if !isdirectory(expand(s:dein_repo_dir))
  execute '!git clone https://github.com/Shougo/dein.vim '. s:dein_repo_dir
endif
let &runtimepath = &runtimepath. ','. s:dein_repo_dir

let s:dein_toml = $XDG_CONFIG_HOME. '/nvim/dein.toml'
let s:dein_lazy_toml = $XDG_CONFIG_HOME. '/nvim/dein_lazy.toml'
let s:dein_ddc_toml = $XDG_CONFIG_HOME. '/nvim/ddc.toml'

let s:path = $XDG_CACHE_HOME . '/dein'
if dein#min#load_state(s:path)
  call dein#begin(s:path, [
        \ expand('<sfile>'), s:dein_toml, s:dein_lazy_toml
        \ ])
  call dein#load_toml(s:dein_toml, {'lazy': 0})
  call dein#load_toml(s:dein_lazy_toml, {'lazy': 1})
  call dein#load_toml(s:dein_ddc_toml, {'lazy': 1})
  call dein#end()
  call dein#save_state()
endif

" install plugin if not installed
if has('vim_starting') && dein#check_install()
  call dein#install()
endif

filetype plugin indent on
syntax enable
