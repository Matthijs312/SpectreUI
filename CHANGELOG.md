# Changelog

## v3.1

### Added
- Noclip toggle — walk through walls and objects
- Dedicated Movement tab — moved Infinite Jump, Noclip, and Fullbright out of Hitbox into their own tab

---

## v3.0

### Added
- Fullbright toggle — removes all darkness, fog, and shadows instantly
- Saves/restores original lighting values when toggled off

---

## v2.9

### Added
- Crosshair color selector — 5 presets: White, Red, Green, Cyan, Accent
- Center dot toggle — small circular dot at crosshair center
- Dedicated Crosshair tab (moved out of Aim Lock tab)

---

## v2.8

### Added
- Crosshair overlay — custom crosshair drawn at screen center with adjustable size, gap, and thickness
- Crosshair toggle, size, gap, and thickness sliders
- Crosshair settings saved/loaded with config

---

## v2.7

### Added
- Hitbox transparency slider — adjust how see-through expanded heads are (0%–100%)

### Fixed
- Aim lock could not be toggled off — right-click was blocked by game camera's `gameProcessedEvent`
- Toggle buttons could permanently lock if their callback errored (debounce never reset)
- Keybind rebind button could accidentally capture its own click as the new keybind
- ESP highlights and billboards leaked when players left the game
- Aim lock stayed locked to a player who left mid-game
- FOV circle was offset ~18px from the actual aim lock center due to GUI inset
- Pressing Escape during keybind rebinding no longer sets the keybind to Escape (now cancels)

### Improved
- Load Config now instantly updates all toggles, sliders, and keybind labels in the UI
- Reset to Defaults now syncs all UI controls to match the reset state
- Startup config auto-load syncs UI so toggles reflect saved settings immediately

## v2.6

### Added
- 4th status indicator dot on toggle button for Infinite Jump

## v2.5

### Improved
- Window now has a drop shadow and blue-to-purple gradient accent bar
- Title bar taller with better spacing, `//` separator style, version badge with accent border
- Divider fades out at edges with gradient transparency
- Sidebar wider (138px) with subtle background hover on tabs
- Section headers now have a small accent dot indicator
- All rows (toggles, sliders, selectors) use consistent 10px rounded corners
- Toggle/slider rows slightly taller for better click targets
- Home tab hero card taller with gradient accent bar and larger title
- Floating toggle button slightly larger (50px)
- Toast notifications rounder and taller
- Close/minimize buttons vertically centered in title bar

## v2.4

### Added
- Infinite Jump toggle in Hitbox tab — jump mid-air unlimited times
- Infinite Jump state persists with config save/load

## v2.3

### Added
- Minimize button — collapse window to title bar only, click to restore
- Reset to Defaults button in Settings — restores all settings and keybinds in one click
- Executor filesystem detection — startup notification tells you if config saving is supported

## v2.2

### Added
- Keybind customization — rebind toggle menu and aim lock keys in Settings tab
- Config save/load — persists all toggle states, slider values, and keybinds to file
- Toast notification system — on-screen popups for feature toggles, config saves, and startup
- Config auto-loads on startup if a saved config exists
- Save/Load buttons in Settings tab

## v2.1

### Added
- Resizable window with drag handle (min 380x320, max 800x600)
- FOV circle overlay for aim lock with adjustable radius (50–500px)
- Aim lock smoothness slider (5%–100%)
- Draggable floating toggle button
- Active feature indicator dots on toggle button (ESP, Aim, Hitbox)
- Smoothness explanation label in Aim Lock tab

### Fixed
- Close button and tab icons rendering as boxes (replaced Unicode with ASCII)
- Memory leak from CharacterAdded connections not being disconnected on PlayerRemoving
- Aim lock target error when character gets reparented mid-frame
- Slider input leak — all sliders now share a single global input listener

## v2.0

### Added
- Initial release
- ESP highlights with team colors, name tags, health bars, distance labels
- Aim lock with toggle/hold modes and teammate ignore
- Head hitbox expander with size multiplier and teammate skip
- Tabbed sidebar UI with dark theme
- Draggable window
- INSERT keybind to toggle menu
- Floating "S" button to toggle menu
