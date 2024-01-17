local wezterm = require 'wezterm'

local config = {};
config.font = wezterm.font("Cica")
config.use_ime = true
config.font_size = 14.0
config.color_scheme = "Tokyo Night"
config.default_cwd = "~/"

local handle = io.popen("which nu", "w")
if handle == nil then
	print("handle is null")
	config.default_prog = { "bash" }
else
	local nu_path = handle:read("a")
	handle:close()
	print(nu_path)
	if nu_path then
		config.default_prog = { nu_path }
	end
end


return config
