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

-- Use nu as the default shell when it is available.
local is_windows = wezterm.target_triple:find("windows") ~= nil
local handle = io.popen(is_windows and "where nu" or "which nu", "r")
if handle then
	local output = handle:read("a") or ""
	-- close() is falsy when the command failed (nu not found);
	-- in that case `output` may hold an error message, not a path.
	local ok = handle:close()
	if ok then
		local nu_path = output:match("[^\r\n]+")
		if nu_path then
			config.default_prog = { nu_path }
		end
	end
end


return config
