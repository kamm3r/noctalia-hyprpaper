# Hyprpaper

Wallpaper selector plugin for Noctalia with local wallpapers.

## Features

- **Local Wallpapers**: Browse and select wallpapers from a local directory
- **Multiple View Modes**: Single wallpaper or favorites-based selection
- **Multi-Monitor Support**: Configure separate wallpapers per monitor
- **Fill Modes**: Support for cover, fill, contain, and center fill modes
- **Splash Effect**: Optional splash overlay on wallpaper changes

## Configuration

The plugin can be configured through the Noctalia settings or by editing the `metadata.defaultSettings` in `manifest.json`:

| Setting | Type | Description |
|---------|------|-------------|
| `directory` | string | Path to wallpaper directory (default: `~/Pictures/Wallpapers`) |
| `viewMode` | string | Display mode: `single` or `favorites` |
| `setWallpaperOnAllMonitors` | boolean | Apply wallpaper to all monitors |
| `enableMultiMonitorDirectories` | boolean | Enable separate directories per monitor |
| `monitorDirectories` | array | Per-monitor directory mappings |
| `fillMode` | string | Image fill mode: `cover`, `fill`, `contain`, `center` |
| `panelPosition` | string | Panel position: `bottom_center`, `top_center`, etc. |
| `splash` | boolean | Enable splash effect on change |
| `splash_offset` | number | Splash animation offset |
| `splash_opacity` | number | Splash opacity (0-1) |
| `ipc` | boolean | Enable Hyprland IPC for wallpaper control |

## Requirements

- Noctalia 3.6.0+
- Hyprland
- hyprpaper

## Installation

This plugin is typically pre-installed with Noctalia. If you need to install it manually, place the plugin folder in your Noctalia plugins directory.

## Usage

1. Open the wallpaper panel from the Noctalia bar
2. Browse local wallpapers
3. Click a wallpaper to apply it
4. Use the favorites feature to save frequently used wallpapers
