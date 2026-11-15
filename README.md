# omarchy-plugins

Personal plugins for the [Omarchy](https://omarchy.org/) shell (Quickshell bar).

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

## Install

Each plugin lives in its own folder, so install by copying (or symlinking) that folder into the shell's plugin directory:

```bash
git clone https://github.com/Cyronius/omarchy-plugins.git ~/code/omarchy-plugins
cp -r ~/code/omarchy-plugins/workspace-title ~/.config/omarchy/plugins/cyrus.workspace-title
omarchy plugin enable cyrus.workspace-title --after omarchy.workspaces
omarchy restart shell
```

After editing a plugin's QML, run `omarchy restart shell`. The shell's hot-reload notices the change but can keep running the old code.
