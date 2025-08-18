if exists('g:loaded_uuid_generator')
  finish
endif
let g:loaded_uuid_generator = 1

augroup uuid-generator
  autocmd!
  autocmd User DenopsPluginPost:uuid-generator call denops#notify('uuid-generator', 'init', [])
augroup END
