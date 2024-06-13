local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.default_prog = { wezterm.home_dir .. '/.local/bin/zellij', '-l', 'welcome' }
config.color_scheme = 'GruvboxDark'
config.font = wezterm.font 'JetBrainsMono Nerd Font'

return config
