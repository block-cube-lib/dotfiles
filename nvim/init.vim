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
  let g:python3_host_prog=$PYTHON3_PATH. '/python.exe'
  let g:python_host_prog=$PYTHON2_PATH. '/python.exe'
endif
let &runtimepath = expand(&runtimepath)

if $XDG_CONFIG_HOME == ''
  let $XDG_CONFIG_HOME= expand('~/.config')
endif

if $XDG_CACHE_HOME == ''
  let $XDG_CACHE_HOME= expand('~/.cache')
endif

"
" system
"
set shellslash
" set t_Co=255
if has("termguicolors")
  set termguicolors
endif
if executable('fish')
  set sh=fish
endif

"
" shell
"
tnoremap <silent> <C-Q> <C-\><C-n>

"
" completion
"
set ignorecase
set smartcase
set wrapscan

" file and directory name completion
set wildignorecase
set wildmode=list:full

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
function! s:SafeMakeDirectory(name)
  if !isdirectory(expand(a:name))
    call mkdir(a:name, 'p')
  endif
endfunction

" swap file
set swapfile
let &directory = expand($XDG_CACHE_HOME). '/nvim/swap'
call s:SafeMakeDirectory(&directory)

" undo file
set undofile
let &undodir = expand($XDG_CACHE_HOME). '/nvim/undo'
call s:SafeMakeDirectory(&undodir)

" backup file
set backup
let &backupdir = expand($XDG_CACHE_HOME). '/nvim/backup'
call s:SafeMakeDirectory(&backupdir)

"
" editor
"
set title
set matchpairs+=<:>

set list
set listchars=tab:>-,trail:~

set number
set cursorline
set ruler

set hidden

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
augroup set_filetypes
  autocmd!
  autocmd BufNewFile,BufRead *.swift setf swift
  autocmd BufNewFile,BufRead *.pu setf plantuml
  autocmd BufNewFile,BufRead *.fish setf fish
  autocmd BufNewFile,BufRead *.vue setf html
augroup END

"
" tag
"
function! UpdateTags()
  let tag_list = split(glob("$HOME/tags/*"), "\n")
  for file in tag_list
    if stridx(&tags, file) < 0
      let &tags = &tags. ','. file
    endif
  endfor
endfunction

call UpdateTags()

"
" plugin
"
if has('python3')
  source $XDG_CONFIG_HOME/nvim/dein.vim
endif
