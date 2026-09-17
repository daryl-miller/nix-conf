# Contract: New Module Interface

This project has no network/API surface; its "interface" is the set of declarative options
each new concern module exposes for a host/user config to import, per Constitution
Principle III (a host must be addable by importing existing shared modules, not forking
them). This mirrors the `Module | Settings owned` table convention in
`modules/nixos/README.md` and `modules/home/README.md` — implementing this feature MUST add
one row per new file to those tables.

## `modules/nixos/hyprland.nix` (host-agnostic, imported by `hosts/laptop/configuration.nix`)

Owns: `programs.hyprland.enable`, XDG desktop portal wiring for Hyprland,
`hardware.bluetooth.enable`, `services.blueman.enable` (required system-wide by
home-manager's `services.blueman-applet`, used in `modules/home/hypr-extras.nix`).

**Guarantee**: Importing this module adds a selectable Hyprland session without altering any
option owned by `modules/nixos/desktop.nix` (Plasma stays untouched — FR-001).

## `modules/home/theme.nix`

Owns: the Catppuccin Mocha palette/font/corner-radius/animation-curve values, exported as an
attrset other home modules import.

**Guarantee**: No other module hardcodes a color/font value; all visual consistency (FR-010)
flows from this single file.

## `modules/home/hyprland.nix`

Owns: `wayland.windowManager.hyprland.settings` (bindings, monitors, animations, window
rules) and `wayland.windowManager.hyprland.plugins`.

**Guarantee**: Every keybinding listed in `contracts/keybindings.md` is bound here and
requires no post-rebuild manual step (FR-002, FR-011).

## `modules/home/waybar.nix`

Owns: `programs.waybar.settings` / `programs.waybar.style`.

**Guarantee**: Bar is visible on Hyprland startup with the modules listed in FR-003/FR-009
without further configuration.

## `modules/home/hypr-shell.nix`

Owns: `programs.fuzzel`, `services.mako`, `programs.hyprlock`, `services.hypridle`,
`services.awww` (or equivalent wallpaper-daemon option), `programs.kitty`, and the
`grimblast` package/keybinding wiring.

**Guarantee**: Every "baseline sane default" capability (launcher, notifications, lock/idle,
wallpaper, screenshot, terminal) is present and functional immediately after rebuild with no
manual step (FR-004–FR-008).

## `modules/home/hypr-extras.nix`

Owns: `services.cliphist.enable` + `wl-clipboard` (clipboard), `wf-recorder` (screen
recording, plain package), `hyprpicker` (color picker, plain package),
`services.blueman-applet.enable` + `services.network-manager-applet.enable` (tray applets;
`services.playerctld.enable` for the media-key/MPRIS backend `waybar.nix`'s widget reads).

**Guarantee**: Exactly the nice-to-have tools selected in spec FR-009 are present; nothing
beyond that list is installed by this feature (spec SC-004).
