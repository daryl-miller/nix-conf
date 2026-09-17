# Phase 1 Data Model: Hyprland Desktop Environment

This feature has no runtime application data — it is declarative system/user configuration.
The "entities" below are the configuration concepts each new module owns, mirroring the
`Module | Settings owned` convention already used in `modules/nixos/README.md` and
`modules/home/README.md`, so the tables there can be extended directly once implemented.

## System Session (owned by `modules/nixos/hyprland.nix`)

Registers Hyprland as a selectable session without touching the existing Plasma session.

| Field | Description |
|---|---|
| `programs.hyprland.enable` | Installs Hyprland and registers its Wayland session entry with the existing SDDM display manager. |
| XDG portal wiring | Ensures `xdg-desktop-portal-hyprland` is the active portal backend when the Hyprland session is running, needed for screen sharing/file pickers. |
| `hardware.bluetooth.enable` | Enables the Bluetooth hardware stack backing FR-009's tray applet. |
| `services.blueman.enable` | Enables the system-wide `blueman` D-Bus service the home-manager `services.blueman-applet` (FR-009) requires to function. |

**Relationships**: Sibling of `modules/nixos/desktop.nix` (Plasma); both are imported by
`hosts/laptop/configuration.nix`. Neither module modifies the other (FR-001: Plasma remains
an untouched fallback).

## Theme (owned by `modules/home/theme.nix`)

The single source of truth for the Catppuccin Mocha palette (research.md #10), consumed by
every other home module below so the look stays consistent (FR-010) and a future palette
swap touches one file.

| Field | Description |
|---|---|
| `colors.*` | Named palette values (base, surface, accent colors, etc.) exposed as an importable attrset. |
| `font` | The shared UI font/monospace font used by `waybar`, `fuzzel`, `kitty`. |
| `cornerRadius` / `animationCurve` | Shared visual constants applied to Hyprland window decoration and `waybar`. |

**Relationships**: Imported by `hyprland.nix`, `waybar.nix`, `hypr-shell.nix`, and the
`kitty` config; has no dependencies of its own.

## Compositor Session Config (owned by `modules/home/hyprland.nix`)

The `wayland.windowManager.hyprland` home-manager configuration itself.

| Field | Description |
|---|---|
| `bindings` | Keybinding set required by FR-002 (terminal, launcher, close window, workspace switch/move, window move/resize, lock). |
| `monitors` | Monitor/output configuration for the laptop panel (external-monitor edge cases are documented, not auto-handled — see spec Edge Cases). |
| `animations` | Window-open/close/move animation curves, sourced from Theme (FR-010). |
| `plugins` | Declares `hy3` and `borders-plus-plus` (FR-009). |
| `windowRules` | Baseline sane-default window placement/floating rules. |

**Relationships**: Depends on Theme; references binaries provided by `hypr-shell.nix` and
`hypr-extras.nix` (e.g., the terminal, launcher, and lock keybindings call into those
modules' packages) without duplicating their configuration.

## Status Bar (owned by `modules/home/waybar.nix`)

| Field | Description |
|---|---|
| `modules-left/center/right` | Workspace indicator, clock, tray, network, battery, volume (FR-003) plus MPRIS media controls and CPU/memory/temperature indicators (FR-009 extra widgets). |
| `style` | Catppuccin Mocha styling sourced from Theme. |

**Relationships**: Depends on Theme; surfaces `blueman`/`nm-applet` tray icons owned by
`hypr-extras.nix` via the tray module, without owning those packages itself.

## Baseline Companion Daemons (owned by `modules/home/hypr-shell.nix`)

Groups the daemons/tools required for the session to count as a complete "sane defaults"
desktop, as opposed to optional nice-to-haves.

| Field | Description |
|---|---|
| `launcher` (`fuzzel`) | FR-004. |
| `notifications` (`mako`) | FR-008. |
| `lock` / `idle` (`hyprlock` / `hypridle`) | FR-005. |
| `wallpaper` (`awww` + default wallpaper asset) | FR-006. |
| `screenshot` (`grimblast` keybinding wiring) | FR-007. |
| `terminal` (`kitty`) | Backing app for the "open terminal" keybinding (FR-002). |

**Relationships**: Depends on Theme; keybindings referencing these tools live in
`hyprland.nix`, not duplicated here.

## Nice-to-Have Companion Tools (owned by `modules/home/hypr-extras.nix`)

| Field | Description |
|---|---|
| `clipboard` (`cliphist` + `wl-clipboard`) | FR-009. |
| `screenRecording` (`wf-recorder`) | FR-009. |
| `colorPicker` (`hyprpicker`) | FR-009. |
| `trayApplets` (`blueman`, `networkmanagerapplet`) | FR-009; surfaced in `waybar`'s tray module. |

**Relationships**: Independent of the other home modules aside from Theme; each tool here
maps 1:1 to one bullet of spec FR-009 so a future "drop a nice-to-have" change touches only
this file.
