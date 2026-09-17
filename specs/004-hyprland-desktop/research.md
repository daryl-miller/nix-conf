# Phase 0 Research: Hyprland Desktop Environment

All items below are plan-level implementation decisions (not spec ambiguities — the spec's
three clarification points were already resolved during `/speckit-specify`). Each follows the
`Decision / Rationale / Alternatives considered` format.

## 1. Hyprland source (flake input vs. nixpkgs)

- **Decision**: Use the `hyprland` package and `programs.hyprland` NixOS module already
  provided by the pinned `nixpkgs` (unstable) input. Do not add a dedicated Hyprland flake
  input.
- **Rationale**: `nixpkgs-unstable` tracks Hyprland releases closely, and Constitution
  Principle II treats adding inputs as a deliberate, reviewed act, while Principle V favors
  the simplest structure that solves the problem. A single pinned source (`nixpkgs`) for both
  the compositor and every companion tool keeps the whole desktop environment updating
  together via one `nix flake update`, rather than needing separately coordinated inputs.
- **Alternatives considered**: The official `hyprwm/Hyprland` flake (bleeding-edge releases,
  but a second input to keep in sync with `nixpkgs`'s own Hyprland-adjacent packages —
  rejected as unnecessary complexity for a personal laptop where release lag of a few weeks
  is not a real cost).

## 2. Session registration / coexistence with Plasma

- **Decision**: `programs.hyprland.enable = true` registers a Wayland session entry that
  SDDM (already enabled in `modules/nixos/desktop.nix`) lists natively alongside the existing
  Plasma 6 entry. No display-manager reconfiguration is required to satisfy FR-001.
- **Rationale**: SDDM enumerates all installed session `.desktop` files automatically;
  Plasma 6's registration is untouched by adding Hyprland.
- **Alternatives considered**: Switching display managers (e.g., to `greetd` +
  `tuigreet`, common in minimal Hyprland setups) — rejected: unnecessary churn to an
  already-working, unrelated part of the system, and out of scope per FR-001.

## 3. Status bar

- **Decision**: `waybar`.
- **Rationale**: The de facto standard Wayland status bar for wlroots-based compositors
  including Hyprland; has first-class `programs.waybar` home-manager support and built-in
  modules covering every FR-003/FR-009 indicator needed (workspaces, clock, network,
  battery, volume, tray, CPU/memory/temperature, MPRIS media controls).
- **Alternatives considered**: `ags`/`eww` (far more flexible but require writing a bar from
  scratch in a scripting/markup DSL — more implementation surface than this feature needs).

## 4. Application launcher

- **Decision**: `fuzzel`.
- **Rationale**: Native Wayland launcher (no XWayland dependency), minimal config surface,
  has a `programs.fuzzel` home-manager module, and is fast enough to feel instant (supports
  SC-001/SC-002).
- **Alternatives considered**: `rofi-wayland` (heavier, historically a community fork rather
  than upstream Wayland support); `walker` (newer, Omarchy's own launcher, but not yet
  packaged in `nixpkgs` — would require an extra flake input or building from source,
  rejected per decision #1).

## 5. Notification daemon

- **Decision**: `mako`.
- **Rationale**: Native Wayland notification daemon, lightweight, has a `services.mako`
  home-manager module, satisfies FR-008 with minimal configuration.
- **Alternatives considered**: `dunst` (X11-first with Wayland support bolted on; `mako` is
  the more natural fit alongside the rest of this wlroots-based stack).

## 6. Screen lock & idle behavior

- **Decision**: `hyprlock` (lock screen) + `hypridle` (idle daemon triggering lock/DPMS).
- **Rationale**: Official Hyprland-ecosystem tools maintained by the same project, both
  packaged in `nixpkgs` with `programs.hyprlock` / `services.hypridle` home-manager modules,
  and designed to integrate with Hyprland's IPC directly — satisfies FR-005 with no gluing
  required.
- **Alternatives considered**: `swaylock` + `swayidle` (proven, but built for `sway`; using
  the Hyprland-native pair avoids compositor-specific edge cases).

## 7. Wallpaper

- **Decision**: `awww` (the `nixpkgs` attribute `swww` was renamed to `awww` upstream; the
  binary is still invoked as `awww`).
- **Rationale**: Supports animated transition effects between wallpapers, which fits the
  opinionated, "intentionally configured" look requested for FR-006/FR-010 (SC-003) better
  than a static-only tool.
- **Alternatives considered**: `hyprpaper` (official, simpler, but static — no transition
  effects; rejected in favor of the more polished result `awww` gives for similar effort).

## 8. Screenshot capture

- **Decision**: `grimblast` (packaged directly as `pkgs.grimblast` in `nixpkgs`, confirmed
  T001), which wraps `grim` + `slurp` + `hyprctl` to capture full-screen or a manually
  selected region and copies/saves the result with a confirmation notification.
- **Rationale**: Purpose-built for Hyprland, avoids hand-writing a `grim`+`slurp` wrapper
  script to satisfy FR-007.
- **Alternatives considered**: Hand-rolled `grim`+`slurp` shell script bound directly to a
  keybinding (more code to own for no functional gain over the maintained wrapper).

## 9. Nice-to-have companion tools (FR-009)

| Capability | Decision | Rationale |
|---|---|---|
| Clipboard history | home-manager `services.cliphist` + `wl-clipboard` | Standard Wayland clipboard-history pairing; integrates with `fuzzel` as a picker source. |
| Screen recording | `wf-recorder` (plain package, no dedicated home-manager module) | Minimal, scriptable Wayland screen recorder; keybinding-friendly. |
| Color picker | `hyprpicker` (plain package, no dedicated home-manager module) | Official Hyprland-ecosystem color picker. |
| Extra bar widgets | Built into `waybar` (`mpris`, `cpu`, `memory`, `temperature` modules) + home-manager `services.playerctld` backing `mpris` | No extra daemon config needed beyond `playerctld`; everything else is `waybar` config. |
| Bluetooth/network tray applets | home-manager `services.blueman-applet` + `services.network-manager-applet` | Dedicated home-manager service modules wrapping `blueman`/`nm-applet` as user systemd services; `services.blueman-applet` additionally requires `services.blueman.enable = true` at the NixOS level (added to `modules/nixos/hyprland.nix`), surfaced via `waybar`'s tray module. |
| Extra Hyprland plugins | `hyprlandPlugins.hy3` (i3-style alternate tiling layout) + `hyprlandPlugins.borders-plus-plus` (animated multi-borders) | Both are packaged in `nixpkgs` under `hyprlandPlugins.*`, declarable via home-manager's `wayland.windowManager.hyprland.plugins` with no extra flake input, keeping decision #1 intact. `hyprexpo` (originally planned) isn't packaged under this pinned `nixpkgs`; the next choice, `hyprspace` (workspace overview), *is* packaged but fails to compile against this pinned Hyprland version (verified during implementation — stale upstream source pin vs. the current Hyprland ABI). `hy3` was verified to build successfully (version `0.56.0.1`, matching the pinned Hyprland `0.56.2`) and is also a closer match to the originally-approved "alternate tiling layout" wording than a workspace overview is. |

## 10. Visual theme (FR-010)

- **Decision**: Adopt **Catppuccin Mocha** as the concrete palette used to realize the
  "Omarchy-style opinionated theme" requirement, applied consistently across Hyprland window
  borders/animations, `waybar`, `fuzzel`, `mako`, `hyprlock`, and the terminal.
- **Rationale**: The spec's own wording ("Omarchy-style") specifies a *category* of theming
  (cohesive palette, rounded corners, animations), not an exact palette to replicate pixel-
  for-pixel. Catppuccin Mocha is a concrete, well-defined dark palette with first-class,
  actively maintained theme support across every component chosen above (`waybar`, `mako`,
  `fuzzel`, `hyprlock`, terminal emulators, GTK/Qt), minimizing bespoke CSS/config this
  feature would otherwise have to hand-write and keeping the result visually cohesive.
- **Alternatives considered**: Hand-authoring a bespoke color scheme (more implementation
  surface, no ecosystem theme support to lean on); Tokyo Night / Gruvbox (also viable and
  similarly well-supported — Catppuccin Mocha was chosen as the single default; swapping
  palettes later is a config-only change confined to `theme.nix`, see Structure Decision in
  `plan.md`).

## 12. Hyprland config format: `hyprlang` vs. `lua`

- **Decision**: Pin `wayland.windowManager.hyprland.configType = "hyprlang"` explicitly in
  `modules/home/hyprland.nix`, rather than accepting home-manager's own default (which is
  `"lua"` for `home.stateVersion >= 26.05`, the stateVersion this config uses).
- **Rationale**: Verified during implementation — home-manager's `lua` generator emits every
  settings key verbatim as `hl.${key}(...)`, which is invalid Lua for any key containing a
  hyphen. This config uses several (`exec-once`, `borders-plus-plus`), so the generated
  `hyprland.lua` would very likely fail to load as-is. `hyprlang` (the classic `.conf`
  format) has no such issue; the generated `hyprland.conf` was inspected directly and
  confirmed to produce correct, standard Hyprland syntax for every block used here (`bind`,
  `general`, `decoration`, `animations`, `dwindle`, `plugin`, `exec-once`, `monitor`).
- **Alternatives considered**: Keeping the `lua` default and renaming the offending keys —
  rejected: `exec-once` is a fixed Hyprland keyword that can't be renamed, so this isn't
  fully avoidable within `lua` mode without deeper workarounds beyond this feature's scope.

## 11. Terminal emulator

- **Decision**: `kitty`.
- **Rationale**: No terminal emulator is currently configured anywhere in this repo (Plasma
  users have relied on Konsole as the desktop-provided default, which Hyprland has no
  equivalent of), so FR-002's "open terminal" keybinding needs one. `kitty` is GPU-
  accelerated, has a `programs.kitty` home-manager module, and has first-class Catppuccin
  Mocha theme support consistent with decision #10.
- **Alternatives considered**: `foot` (lighter weight, but less common Catppuccin/theming
  ecosystem polish); `alacritty` (comparable, no strong differentiator over `kitty` for this
  use case).
