# SPECTRE ESP v2.5

A polished Roblox ESP toolkit with a dark, modern UI. Built as a single-file Lua script with no external dependencies.

## Features

### ESP Highlights
- Player highlights with team-color support
- Toggleable name tags, health bars, and distance labels
- Adjustable fill and outline opacity

### Aim Lock
- Camera lock to nearest player within FOV
- Toggle or hold-to-aim modes
- Adjustable smoothness (5%–100%)
- FOV circle overlay with adjustable radius (50–500px)
- Teammate ignore option

### Head Expander
- Expands enemy head hitboxes (1x–12x multiplier)
- Auto-applies to new players and respawns every 2 seconds
- Optional teammate skip

### Movement
- **Infinite Jump** — jump mid-air, unlimited times

### Settings
- **Keybind customization** — rebind toggle menu and aim lock to any key or mouse button
- **Config save/load** — persists all settings, slider values, and keybinds between sessions
- **Reset to defaults** — one-click restore of all settings
- **Toast notifications** — on-screen popups when features are toggled or config is saved/loaded

## UI

- **Dark theme** — custom design system with accent colors, smooth tweens, and rounded corners
- **Tabbed sidebar** — Home, ESP, Aim Lock, Hitbox, Settings
- **Draggable window** — grab the title bar to reposition
- **Resizable window** — drag the bottom-right grip handle (min 380x320, max 800x600)
- **Minimize button** — collapse to title bar only, click again to restore
- **Floating toggle button** — draggable "S" button to open/close the menu from anywhere
- **Status indicators** — three dots on the toggle button show which features are active at a glance
- **Smooth animations** — open/close scale transitions, hover effects, toggle animations

## Keybinds

Default keybinds (rebindable in Settings tab):

| Key | Action |
|---|---|
| `INSERT` | Toggle menu |
| `Right-Click` | Aim lock (toggle or hold, depending on mode) |

## Usage

Execute the script in any Roblox script executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Matthijs312/SpectreUI/refs/heads/main/Spectre.lua"))()
```

Or paste the contents of `Spectre.lua` directly into your executor.

## Disclaimer

This project is for **educational purposes only**. It is intended to demonstrate Roblox UI development, scripting patterns, and game overlay techniques. Use responsibly and in accordance with Roblox's Terms of Service.
