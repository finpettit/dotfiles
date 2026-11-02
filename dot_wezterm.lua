local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Appearance
config.color_scheme = "Catppuccin Macchiato"
config.window_background_opacity = 0.85
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"

-- Font
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 13

-- Window / tab bar
config.initial_cols = 120
config.initial_rows = 28
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- Command palette (matched to Catppuccin Macchiato)
config.command_palette_bg_color = "#1e2030"
config.command_palette_fg_color = "#cad3f5"
config.command_palette_font_size = 13
config.command_palette_rows = 12

-- Keys
config.keys = {
	{
		key = "P",
		mods = "SUPER",
		action = wezterm.action.ActivateCommandPalette,
	},
}

return config
