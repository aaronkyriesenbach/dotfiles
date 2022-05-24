:for ext in ["tex"]
:    execute printf("autocmd BufNewFile *.%s 0r templates/%s", ext, ext)
:endfor
