" Install vim-plug if not found
if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
  silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $HOME/.config/nvim/init.vim
endif

call plug#begin()

Plug 'dracula/vim', {'as': 'dracula'}
Plug 'chrisbra/Colorizer'
Plug 'lervag/vimtex'
Plug 'dcampos/nvim-snippy'
Plug 'honza/vim-snippets'

call plug#end()
