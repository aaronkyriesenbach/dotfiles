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
Plug 'lervag/vimtex'

call plug#end()

filetype plugin on
colorscheme dracula
syntax enable " Syntax highlighting
set number " Line numbers
set cursorline " Highlight current line
set showmatch " Show matching brackets
set incsearch " Dynamic searching

" Tab/indent config
set tabstop=8
set expandtab
set shiftwidth=4
set autoindent
set smartindent
set cindent

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

" Set line length for text files
:for ext in ["txt", "tex"]
:    execute printf("autocmd BufRead,BufNewFile *.%s setlocal textwidth=100", ext)
:endfor

" TeX config
let g:vimtex_view_method = "zathura"
let g:vimtex_compiler_latexmk = {'build_dir': '/tmp'}
let g:vimtex_view_forward_search_on_start = 0

:for ext in ["tex"]
:    execute printf("autocmd BufNewFile *.%s 0r $HOME/.config/nvim/templates/%s", ext, ext)
:endfor
