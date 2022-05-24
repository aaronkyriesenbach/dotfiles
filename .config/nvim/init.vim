:for file in ["plugins", "config", "textwidth", "tex", "templates"]
:    execute printf("source $HOME/.config/nvim/%s.vim", file)
:endfor
