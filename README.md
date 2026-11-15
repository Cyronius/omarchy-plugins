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

### window-grid

A script that toggles the windows on the active workspace between an even grid and normal tiling. The grid is sized to the window count: 2 side by side, 3–4 in a 2x2, 5–6 in a 3x2, 7–9 in a 3x3. A short last row stretches to fill the width. Windows keep their reading order, and the gaps, borders and bar space match Hyprland's own tiling. Gridded windows are floated and tagged `grid`; running the script again puts them back into tiling.

```bash
ln -s ~/code/omarchy-plugins/window-grid/window-grid ~/.local/bin/window-grid
```

Then bind it in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + CTRL + G", "Grid windows", os.getenv("HOME") .. "/.local/bin/window-grid")
```

Needs `jq`.

## Install

Each shell plugin lives in its own folder, so install by copying (or symlinking) that folder into the shell's plugin directory:

```bash
git clone https://github.com/Cyronius/omarchy-plugins.git ~/code/omarchy-plugins
cp -r ~/code/omarchy-plugins/workspace-title ~/.config/omarchy/plugins/cyrus.workspace-title
omarchy plugin enable cyrus.workspace-title --after omarchy.workspaces
omarchy restart shell
```

After editing a plugin's QML, run `omarchy restart shell`. The shell's hot-reload notices the change but can keep running the old code.
