:for ext in ["txt", "tex", "py"]
:    execute printf("autocmd BufRead,BufNewFile *.%s setlocal textwidth=80", ext)
:endfor
