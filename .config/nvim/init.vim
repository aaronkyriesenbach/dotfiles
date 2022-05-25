:for file in ["plugins", "config", "templates", "textwidth"]
:    execute printf("source $HOME/.config/nvim/%s.vim", file)
:endfor
