"
" clang-format
"
function! s:CreateClangFormatCommand()
  let l:clang_format_command_list = ['clang-format', 'clang-format-devel']

  " version 3.x
  for e in range(0, 9)
    call add(l:clang_format_command_list, 'clang-format-3.'.e)
  endfor

  " version 4.x
  call add(l:clang_format_command_list, 'clang-format-4.0')

  " version 5.x
  call add(l:clang_format_command_list, 'clang-format-5.0')

  " version 6.x
  call add(l:clang_format_command_list, 'clang-format-6.0')

  call filter(l:clang_format_command_list, 'executable(v:val)')

  if len(l:clang_format_command_list) > 0
    let s:clang_format_command = l:clang_format_command_list[0]
  elseif
    let s:clang_format_command = ''
  endif
endfunction

function! s:ClangFormat()
  if !exists("s:clang_format_command")
    call <SID>CreateClangFormatCommand()
  endif

  if !executable(s:clang_format_command)
    echo 'not found : clang-format command'
    return
  endif

  let l:now_line = line('.')
  execute ":%! ". s:clang_format_command
  execute ":".l:now_line
endfunction

nnoremap [Clang] <Nop>
nmap <Space>c [Clang]

nnoremap <silent> [Clang]f :call <SID>ClangFormat()<CR>

"
" path
"
function! s:AddPath(path)
  if isdirectory(a:path) && stridx(&path, a:path) < 0
    let &path=&path. ','. a:path
  endif
endfunction

call s:AddPath($PYRITE_PATH)
call s:AddPath($BOOST_PATH)
call s:AddPath($CXX_STD_PATH)
