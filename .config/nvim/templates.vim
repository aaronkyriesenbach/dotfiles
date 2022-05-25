:for ext in globpath("$HOME/.config/nvim/templates", "*", 0, 1)
:    execute printf("autocmd BufNewFile *.%s 0r %s", split(ext, "/")[-1], ext)
:endfor
