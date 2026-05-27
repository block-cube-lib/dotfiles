" Vim syntax file
" Language: Chatwork

if exists("b:current_syntax")
  finish
endif

" Mention to all
syntax match chatworkMentionToAll "\[toall\]"

" Mention to user
syntax match chatworkMentionUser "\[To:\d\+\]"

" Emojis (syntax match for pattern matching)
syntax match chatworkEmoji ":)"
syntax match chatworkEmoji ":("
syntax match chatworkEmoji ":D"
syntax match chatworkEmoji "8\-)"
syntax match chatworkEmoji ":o"
syntax match chatworkEmoji ";)"
syntax match chatworkEmoji ";("
syntax match chatworkEmoji "(sweat)"
syntax match chatworkEmoji ":|"
syntax match chatworkEmoji ":\*"
syntax match chatworkEmoji ":p"
syntax match chatworkEmoji "(blush)"
syntax match chatworkEmoji ":\^)"
syntax match chatworkEmoji "|-)"
syntax match chatworkEmoji "(inlove)"
syntax match chatworkEmoji "]:)"
syntax match chatworkEmoji "(talk)"
syntax match chatworkEmoji "(yawn)"
syntax match chatworkEmoji "(puke)"
syntax match chatworkEmoji "(emo)"
syntax match chatworkEmoji "8-|"
syntax match chatworkEmoji ":#)"
syntax match chatworkEmoji "(nod)"
syntax match chatworkEmoji "(shake)"
syntax match chatworkEmoji "(\^\^;)"
syntax match chatworkEmoji "(whew)"
syntax match chatworkEmoji "(clap)"
syntax match chatworkEmoji "(bow)"
syntax match chatworkEmoji "(roger)"
syntax match chatworkEmoji "(flex)"
syntax match chatworkEmoji "(dance)"
syntax match chatworkEmoji "(:/)"
syntax match chatworkEmoji "(gogo)"
syntax match chatworkEmoji "(think)"
syntax match chatworkEmoji "(please)"
syntax match chatworkEmoji "(quick)"
syntax match chatworkEmoji "(anger)"
syntax match chatworkEmoji "(devil)"
syntax match chatworkEmoji "(lightbulb)"
syntax match chatworkEmoji "(\*)"
syntax match chatworkEmoji "(h)"
syntax match chatworkEmoji "(F)"
syntax match chatworkEmoji "(cracker)"
syntax match chatworkEmoji "(eat)"
syntax match chatworkEmoji "(\^)"
syntax match chatworkEmoji "(coffee)"
syntax match chatworkEmoji "(beer)"
syntax match chatworkEmoji "(handshake)"
syntax match chatworkEmoji "(y)"

" Code block
syntax region chatworkCodeBlock matchgroup=chatworkCodeStart start="\[code\]" end="\[\/code\]" contains=ALLBUT,@Spell

" Quote block
syntax region chatworkQuoteBlock matchgroup=chatworkQuoteStart start="\[引用 aid=\d\+ time=\d\+\]" end="\[\/引用\]" contains=ALLBUT,@Spell

" Old quote format (keep it just in case, remove if not needed)
syntax region chatworkQuote matchgroup=chatworkQuoteStart start="\[qt\]" end="\[\/qt\]" contains=ALLBUT,@Spell

" Reply
syntax match chatworkReply "\[返信 aid=\d\+ to=\d\+-\d\+\]"

" Task (start/end/assignee, etc., as needed)
syntax region chatworkTask matchgroup=chatworkTaskStart start="\[task\]" end="\[\/task\]" contains=ALLBUT,@Spell

" URL
syntax match chatworkURL "https\?:\/\/[^[:space:]]\+"

" Info block (no title)
syntax region chatworkInfoBlock matchgroup=chatworkInfoStart start="\[info\]" end="\[\/info\]" contains=ALLBUT,@Spell

" Info block (with title)
syntax region chatworkInfoBlock matchgroup=chatworkInfoStart start="\[info\]" end="\[\/info\]" contains=ALLBUT,@Spell

" Info block title region
syntax region chatworkInfoTitleRegion contained matchgroup=chatworkInfoTitleStart start="\[title\]" end="\[\/title\]"

" Highlight settings (adjust according to your color scheme)
hi def link chatworkMentionToAll Special
hi def link chatworkMentionUser Special
hi def link chatworkEmoji Constant
hi def link chatworkCodeBlock Special
hi def link chatworkCodeStart Delimiter
hi def link chatworkQuoteBlock Comment
hi def link chatworkQuoteStart Delimiter
hi def link chatworkReply Special
hi def link chatworkTask Todo
hi def link chatworkTaskStart Delimiter
hi def link chatworkURL Underlined
hi def link chatworkInfoBlock Statement
hi def link chatworkInfoStart Delimiter
hi def link chatworkInfoTitleRegion Title
hi def link chatworkInfoTitleStart Delimiter

let b:current_syntax = "chatwork"
