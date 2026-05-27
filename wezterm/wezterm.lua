local wezterm = require 'wezterm'

local config = wezterm.config_builder();

config.automatically_reload_config = true
config.font = wezterm.font("Cica")
config.use_ime = true
config.font_size = 15.0
config.color_scheme = "Tokyo Night"
config.default_cwd = "~/"
config.window_decorations = "RESIZE"
config.show_new_tab_button_in_tab_bar = false
config.window_background_opacity = 0.85
config.macos_window_background_blur = 10

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
