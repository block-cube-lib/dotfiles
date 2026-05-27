; extends

((fenced_code_block
  (info_string
    (language) @_lang)
  (code_fence_content) @injection.content)
 (#any-of? @_lang "cs" "csharp")
 (#set! injection.language "c_sharp"))
