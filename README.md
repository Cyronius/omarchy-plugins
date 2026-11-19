# omarchy-plugins

Personal plugins and scripts for [Omarchy](https://omarchy.org/): shell (Quickshell bar) widgets and Hyprland helpers.

## Plugins

### workspace-title (`cyrus.workspace-title`)

A bar label naming the active workspace, to keep track of what each workspace is for.

- **Left-click**: rename the workspace. Enter saves, Esc cancels, an empty name clears it.
- **Middle-click**: clear the name.
- **Right-click**: cycle the display mode:
  - `auto`: the name, or the active window's title if there is no name
  - `both`: `name · window title`, with the window title dimmed and cut off first
  - `name`: the name only
  - `window`: the window title only

Names persist per workspace in `~/.local/state/omarchy/workspace-titles.json`.

Settings (in `~/.config/omarchy/shell.json`, or via `omarchy bar set cyrus.workspace-title <key> <value>`):

| Key        | Default | Meaning                                  |
|------------|---------|------------------------------------------|
| `display`  | `auto`  | `auto`, `both`, `name` or `window`       |
| `maxWidth` | `240`   | Maximum label width in pixels            |

To rename from a key binding, have it run `omarchy-shell cyrus.workspace-title toggle`.

### window-grid and window-overview

- **Super+Ctrl+G** switches the active workspace to Dwindle and arranges its windows in a grid of native Hyprland tiles. Four windows make a 2×2 grid. Drag shared borders to resize adjacent tiles together.
- **Super+Ctrl+Shift+Tab** opens an overview of the current workspace with app icons and window titles. Click a card or use the arrow keys and Enter to focus it. Escape closes the overview.

Both helpers need Python 3 and Hyprland 0.56 with Omarchy's Lua configuration. The overview also needs `python-gobject` and `gtk4`.

```bash
ln -s ~/code/omarchy-plugins/window-grid/window-grid ~/.local/bin/window-grid
ln -s ~/code/omarchy-plugins/window-overview/window-overview ~/.local/bin/window-overview
```

Add these bindings to `~/.config/hypr/bindings.lua`. Replace any existing Super+Ctrl+G entry.

```lua
o.rebind("SUPER + CTRL + G", "Tile windows in a grid", os.getenv("HOME") .. "/.local/bin/window-grid")
o.bind("SUPER + CTRL + SHIFT + TAB", "Workspace window overview", os.getenv("HOME") .. "/.local/bin/window-overview")
hl.window_rule({
  match = { class = "local[.]omarchy[.]WindowOverview" },
  float = true,
  center = true,
})
```

Run `hyprctl reload` and `hyprctl configerrors` after saving.

## Install

Each shell plugin lives in its own folder, so install by copying (or symlinking) that folder into the shell's plugin directory:

```bash
git clone https://github.com/Cyronius/omarchy-plugins.git ~/code/omarchy-plugins
cp -r ~/code/omarchy-plugins/workspace-title ~/.config/omarchy/plugins/cyrus.workspace-title
omarchy plugin enable cyrus.workspace-title --after omarchy.workspaces
omarchy restart shell
```

After editing a plugin's QML, run `omarchy restart shell`. The shell's hot-reload notices the change but can keep running the old code.
