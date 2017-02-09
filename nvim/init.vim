"
" encoding
"

"set encoding=utf-8
scriptencoding utf-8
set fileencoding=utf-8
set fileencodings=utf-8,ucs-bom,iso-2022-jp-3,enc-jp,cp932,sjis
set fileformats=unix,dos,mac

if has('unix')

elseif has('windows')
  let g:python3_host_prog = $PYTHON_PATH. '/python.exe'
endif
let &runtimepath = expand(&runtimepath)

if empty($XDG_CONFIG_HOME)
  let &XDG_CONFIG_HOME= expand('~/.config')
endif

if empty($XDG_CONFIG_HOME)
  let &XDG_CACHE_HOME= expand('~/.cache')
endif

"
" system
"
set shellslash
set sh=zsh

"
" completion
"
set ignorecase
set smartcase
set wrapscan

"
" alert
"
set noerrorbells
set novisualbell
set visualbell t_vb=

"
" syntax
"
syntax enable
syntax on

"
" filetype
"
filetype indent plugin on

"
" system files
"
let &directory = expand(&directory)
set undofile
let &undodir = $XDG_CACHE_HOME. '/nvim/undo'

"
" editor
"
set title
set matchpairs+=<:>

set list
set listchars=tab:>-,trail:~

set number
set ruler

"
" indent
"
set expandtab " tab to space
set tabstop=2
set shiftwidth=2

set cindent

"ime
set iminsert=0
set imsearch=0

set ambiwidth=double

set nowrap            " scroll

"
" search
"
set showmatch matchtime=1

"
" status line
"
set cmdheight=2
set laststatus=2
set showcmd

set wildmenu

"
" filetype
"
augroup file_type
  autocmd!
  autocmd BufNewFile, BufRead *.{md,mdwn,mkd,mkdn} setl filetype=markdown
  autocmd BufNewFile, BufRead *.cmake, CmakeLists.txt setl filetype=cmake
  autocmd BufRead $LIBCXX_DIR/* setl filetype=cpp
augroup END

"
" plugin
"
source $XDG_CONFIG_HOME/nvim/dein.vim

