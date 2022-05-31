:for file in ["plugins", "config", "templates"]
:    execute printf("source $HOME/.config/nvim/%s.vim", file)
:endfor
