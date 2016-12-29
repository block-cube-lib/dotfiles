
function! s:ClangFormat()
  if !executable('clang-format')
    return
  endif
  let l:now_line = line('.')
  execute ":%! clang-format"
  execute ":".l:now_line
endfunction

nnoremap [Clang] <Nop>
nmap <Space>c [Clang]

nnoremap <silent> [Clang]f :call <SID>ClangFormat()<CR>
