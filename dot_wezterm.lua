local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- Platform
local is_mac = wezterm.target_triple:find("darwin") ~= nil
local is_windows = wezterm.target_triple:find("windows") ~= nil

local mod = is_mac and "SUPER" or "CTRL|SHIFT"
local mod_shift = is_mac and "SUPER|SHIFT" or "CTRL|SHIFT|ALT"

-- Plugins
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local smart_splits = wezterm.plugin.require("https://github.com/smart-splits-nvim/backend-wezterm")

-- Persistent sessions
if is_mac then
	config.unix_domains = { { name = "unix" } }
	config.default_gui_startup_args = { "connect", "unix" }
end

-- Appearance
config.color_scheme = "Catppuccin Macchiato"
config.window_background_opacity = 0.85
config.window_padding = { left = 8, right = 8, top = 6, bottom = 4 }
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.6 }
config.audible_bell = "Disabled"
config.max_fps = 120

if is_mac then
	config.macos_window_background_blur = 20
	config.window_decorations = "RESIZE"
	config.send_composed_key_when_left_alt_is_pressed = false
elseif is_windows then
	for _, dom in ipairs(wezterm.default_wsl_domains()) do
		if not dom.distribution:lower():find("docker") then
			dom.default_cwd = "~"
			config.wsl_domains = { dom }
			config.default_domain = dom.name
			break
		end
	end
	config.win32_system_backdrop = "Acrylic"
end

-- Remote (SSH) tint
local remote_scheme_name = "Catppuccin Macchiato (SSH)"
local remote_scheme = wezterm.color.get_builtin_schemes()["Catppuccin Macchiato"]
remote_scheme.background = "#3b1f2b"
config.color_schemes = { [remote_scheme_name] = remote_scheme }

local function is_remote(domain, process, user_vars)
	if domain and domain:find("^SSH") then
		return true
	end
	if process and (process:find("[/\\]ssh$") or process:find("[/\\]ssh%.exe$") or process:find("[/\\]mosh")) then
		return true
	end
	local prog = user_vars and user_vars.WEZTERM_PROG or ""
	return prog:find("^%s*ssh%s") ~= nil or prog:find("^%s*mosh%s") ~= nil
end

local function pane_is_remote(pane)
	return is_remote(pane:get_domain_name(), pane:get_foreground_process_name(), pane:get_user_vars())
end

wezterm.on("update-status", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	local wanted = pane_is_remote(pane) and remote_scheme_name or nil
	if overrides.color_scheme ~= wanted then
		overrides.color_scheme = wanted
		window:set_config_overrides(overrides)
	end
end)

wezterm.on("format-tab-title", function(tab)
	local p = tab.active_pane
	if is_remote(p.domain_name, p.foreground_process_name, p.user_vars) then
		return {
			{ Background = { Color = tab.is_active and "#ed8796" or "#5b2f3b" } },
			{ Foreground = { Color = tab.is_active and "#24273a" or "#cad3f5" } },
			{ Text = " " .. (tab.tab_title ~= "" and tab.tab_title or p.title) .. " " },
		}
	end
end)

-- Clickable file:line links
config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
	regex = [[(/?\b[\w./-]*\.php):(\d+)\b]],
	format = "phpfile:$1:$2",
})

wezterm.on("open-uri", function(window, pane, uri)
	local file, line = uri:match("^phpfile:(.+):(%d+)$")
	if not file then
		return
	end
	if file:sub(1, 1) ~= "/" then
		local cwd = pane:get_current_working_dir()
		if cwd then
			local dir = type(cwd) == "string" and cwd:gsub("^file://[^/]*", "") or cwd.file_path
			file = dir:gsub("/$", "") .. "/" .. file
		end
	end
	if is_mac then
		wezterm.background_child_process({ "open", "phpstorm://open?file=" .. file .. "&line=" .. line })
	else
		window:perform_action(
			act.SplitHorizontal({ domain = "CurrentPaneDomain", args = { "nvim", "+" .. line, file } }),
			pane
		)
	end
	return false
end)

-- Font
config.font = wezterm.font("JetBrains Mono")
config.font_size = 13
config.adjust_window_size_when_changing_font_size = false

-- Window / tab bar
config.initial_cols = 120
config.initial_rows = 28
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- Scrollback
config.scrollback_lines = 20000

-- Command palette
config.command_palette_bg_color = "#1e2030"
config.command_palette_fg_color = "#cad3f5"
config.command_palette_font_size = 13
config.command_palette_rows = 12

-- Keys
config.keys = {
	{ key = "p", mods = is_mac and "SUPER|SHIFT" or "CTRL|SHIFT", action = act.ActivateCommandPalette },

	{ key = "d", mods = mod, action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "d", mods = mod_shift, action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "w", mods = mod, action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "[", mods = mod, action = act.ActivatePaneDirection("Prev") },
	{ key = "]", mods = mod, action = act.ActivatePaneDirection("Next") },
	{ key = "z", mods = is_mac and "SUPER|SHIFT" or "CTRL|SHIFT", action = act.TogglePaneZoomState },
	{ key = "x", mods = is_mac and "SUPER|SHIFT" or "CTRL|SHIFT", action = act.ActivateCopyMode },

	{ key = "UpArrow", mods = mod_shift, action = act.ScrollToPrompt(-1) },
	{ key = "DownArrow", mods = mod_shift, action = act.ScrollToPrompt(1) },
}

if is_mac then
	local zoxide = "/opt/homebrew/bin/zoxide"
	local f = io.open(zoxide, "r")
	if f then
		f:close()
		workspace_switcher.zoxide_path = zoxide
	end

	table.insert(config.keys, { key = "o", mods = "SUPER", action = workspace_switcher.switch_workspace() })
	table.insert(config.keys, { key = "o", mods = "SUPER|SHIFT", action = workspace_switcher.switch_to_prev_workspace() })

	table.insert(config.keys, { key = "LeftArrow", mods = "SUPER", action = act.SendString("\x01") })
	table.insert(config.keys, { key = "RightArrow", mods = "SUPER", action = act.SendString("\x05") })
	table.insert(config.keys, { key = "Backspace", mods = "SUPER", action = act.SendString("\x15") })
end

-- Neovim-aware pane navigation
smart_splits.apply_to_config(config, {
	direction_keys = { "h", "j", "k", "l" },
	modifiers = { move = "CTRL", resize = "CTRL|ALT" },
})

return config
