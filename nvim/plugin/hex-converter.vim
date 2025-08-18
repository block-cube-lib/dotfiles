if exists('g:loaded_hex_converter')
  finish
endif
let g:loaded_hex_converter = 1

augroup hex-converter
  autocmd!
  autocmd User DenopsPluginPost:hex-converter call denops#notify('hex-converter', 'init', [])
augroup END
