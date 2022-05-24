:for ext in ["txt", "tex"]
:    execute printf("autocmd BufRead,BufNewFile *.%s setlocal textwidth=100", ext)
:endfor
