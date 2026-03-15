# Changelog

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
