" Install vim-plug if not found
if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
  silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $HOME/.config/nvim/init.vim
endif

call plug#begin()

Plug 'dracula/vim', {'as': 'dracula'}
Plug 'chrisbra/Colorizer'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'xolox/vim-misc'
Plug 'xolox/vim-notes'

call plug#end()

filetype plugin on
colorscheme dracula
syntax enable " Syntax highlighting
set number " Line numbers
set cursorline " Highlight current line
set showmatch " Show matching brackets
set incsearch " Dynamic searching

" Tab/indent config
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smartindent

set clipboard=unnamedplus

" Use <tab> for trigger completion and navigate to the next complete item
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

inoremap <silent><expr> <Tab>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<Tab>" :
      \ coc#refresh()
