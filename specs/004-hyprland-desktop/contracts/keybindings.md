# Contract: Default Keybindings

The guaranteed keyboard-shortcut surface for FR-002/FR-005/FR-007 and Success Criteria
SC-002, as implemented in `modules/home/hyprland.nix` (core binds) and
`modules/home/hypr-shell.nix` (screenshot and logout binds).

| Action | Binding | Requirement |
|---|---|---|
| Open terminal (`kitty`) | `SUPER + Return` | FR-002 |
| Open application launcher (`fuzzel`) | `SUPER + Space` | FR-002, FR-004 |
| Close focused window | `SUPER + Q` | FR-002 |
| Switch to workspace N (1–10) | `SUPER + [1-9,0]` | FR-002 |
| Move focused window to workspace N (1–10) | `SUPER + SHIFT + [1-9,0]` | FR-002 |
| Move focused window | `SUPER + SHIFT + arrow key` | FR-002 |
| Resize focused window | `SUPER + CTRL + arrow key` | FR-002 |
| Lock screen (manual, `hyprlock`) | `SUPER + L` | FR-002, FR-005 |
| Screenshot: full screen (`grimblast`) | `Print` | FR-007 |
| Screenshot: selected region (`grimblast`) | `SHIFT + Print` | FR-007 |
| Logout / power menu (`wlogout`) | `SUPER + SHIFT + E` | FR-002 |
| Exit Hyprland session immediately | `SUPER + SHIFT + Q` | FR-002 |

Nice-to-have bindings (FR-009, User Story 3):

| Action | Binding | Requirement |
|---|---|---|
| Clipboard history picker (`cliphist` + `fuzzel`) | `SUPER + V` | FR-009 |
| Toggle screen recording (`wf-recorder`) | `SUPER + R` | FR-009 |
| Color picker (`hyprpicker`) | `SUPER + P` | FR-009 |
| Toggle `hy3` alternate tiling layout | `SUPER + T` | FR-009 |

`borders-plus-plus` and the Bluetooth/network tray applets (`blueman`, `nm-applet`) have no
dedicated keybinding — they're always-on (extra border, tray icons).

**Guarantee**: All of the above work immediately after rebuild with no manual configuration
step (constitution Principle I; spec FR-002/FR-011).
