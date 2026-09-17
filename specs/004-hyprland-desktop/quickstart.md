# Quickstart: Validating the Hyprland Desktop Environment

Prerequisites: changes from this feature applied to `hosts/laptop/configuration.nix` and the
`modules/nixos/`/`modules/home/` files listed in `contracts/module-interface.md`.

## 1. Build & activate (Constitution Principle IV)

```sh
nix flake check
sudo nixos-rebuild build --flake .#laptop     # dry build first
sudo nixos-rebuild switch --flake .#laptop    # then activate
```

Both commands must succeed with no errors before continuing.

## 2. Confirm Plasma is untouched (FR-001)

- At the SDDM login screen, confirm **both** "Plasma (X11)"/"Plasma (Wayland)" and a new
  "Hyprland" session entry are listed.
- Log into Plasma once and confirm it starts normally (regression check).

## 3. Log into Hyprland and validate baseline defaults (User Stories 1–2)

Log into the "Hyprland" session, then, using only the keybindings from
`contracts/keybindings.md`:

1. Open a terminal (`kitty`) — confirm it launches with the Catppuccin Mocha theme.
2. Open the application launcher (`fuzzel`) — confirm it appears and can find an installed
   app.
3. Confirm `waybar` is visible showing workspace indicator, clock, network, battery, volume.
4. Switch and move windows between at least two workspaces.
5. Move and resize a window.
6. Close a window.
7. Trigger a screenshot (full screen, then a selected region) via `grimblast` — confirm both
   files are produced.
8. Manually lock the screen (`hyprlock`) — confirm it locks and unlocks with the account
   password.
9. Leave the session idle past the configured `hypridle` timeout — confirm it locks
   automatically without touching input.
10. Trigger a test notification (e.g., `notify-send "test" "hello"`) — confirm `mako` shows
    it.

Expected: all of the above succeed with zero manual configuration, satisfying SC-001–SC-003.

## 4. Validate nice-to-have tools (User Story 3, FR-009)

1. Copy two different pieces of text, open `cliphist`'s picker — confirm both entries are
   selectable and paste correctly.
2. Start and stop a short `wf-recorder` capture — confirm a playable video file is produced.
3. Run `hyprpicker` — confirm it returns a color value from a pixel on screen.
4. Confirm `waybar` shows a media-control widget when a player is active (e.g., start
   playback in a browser) and CPU/memory/temperature indicators at all times.
5. Confirm Bluetooth and network tray icons (`blueman`, `nm-applet`) are present in
   `waybar`'s tray and open their respective GUIs.
6. Confirm the `hy3` alternate tiling layout and `borders-plus-plus` animated borders are
   active (trigger the layout-toggle keybinding and check windows re-tile in the i3-style
   `hy3` layout; observe the extra border on focus change).

Expected: every item above is present and functional (SC-004); nothing beyond the FR-009
list is installed.

## 5. Fallback check (SC-005)

Confirm that if Hyprland were unable to start, the developer could still select the Plasma
session from the same SDDM screen — this is inherently satisfied by step 2 above, since
Plasma's configuration is untouched.
