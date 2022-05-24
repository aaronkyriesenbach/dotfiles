:for ext in ["tex"]
:    execute printf("autocmd BufNewFile *.%s 0r $HOME/.config/nvim/templates/%s", ext, ext)
:endfor
