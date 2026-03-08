# Hyprpaper

Wallpaper selector plugin for Noctalia with local wallpapers and Wallhaven integration.

## Features

- **Local Wallpapers**: Browse and select wallpapers from a local directory
- **Wallhaven Integration**: Search and download wallpapers from Wallhaven
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
| `sortOrder` | string | Sort order: `name`, `date`, or `random` |
| `setWallpaperOnAllMonitors` | boolean | Apply wallpaper to all monitors |
| `enableMultiMonitorDirectories` | boolean | Enable separate directories per monitor |
| `showHiddenFiles` | boolean | Show hidden files in browser |
| `hideWallpaperFilenames` | boolean | Hide filenames in UI |
| `useSolidColor` | boolean | Use solid color instead of wallpaper |
| `solidColor` | string | Hex color for solid color mode |
| `monitorDirectories` | array | Per-monitor directory mappings |
| `favorites` | array | List of favorite wallpaper paths |
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
2. Browse local wallpapers or search Wallhaven
3. Click a wallpaper to apply it
4. Use the favorites feature to save frequently used wallpapers
