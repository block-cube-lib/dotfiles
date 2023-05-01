config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
cache_home = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")

require('base')
require('key_mapping')
require('lazy_nvim')
