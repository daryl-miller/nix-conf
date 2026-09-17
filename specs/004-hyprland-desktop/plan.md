# Implementation Plan: Hyprland Desktop Environment

**Branch**: `004-hyprland-desktop` | **Date**: 2026-09-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-hyprland-desktop/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Add Hyprland as a second, fully-configured desktop session on the `laptop` host, selectable
at SDDM login alongside the existing (untouched) KDE Plasma 6 session. The session ships with
a complete Omarchy-style "sane defaults" baseline (status bar, launcher, notifications,
lock/idle, wallpaper, screenshot, terminal) plus every nice-to-have companion tool and
Hyprland plugin the developer selected during specification (clipboard history, screen
recording, color picker, extra bar widgets, Bluetooth/network tray applets, and two
Hyprland plugins), all themed consistently with the Catppuccin Mocha palette. Everything is
delivered as host-agnostic `modules/nixos/` and `modules/home/` concern modules, matching
this repo's existing module convention, and sourced entirely from the already-pinned
`nixpkgs` input (no new flake inputs).

## Technical Context

**Language/Version**: Nix (nixpkgs `nixos-unstable`), NixOS 26.05 module system,
home-manager module system

**Primary Dependencies**: `hyprland`, `waybar`, `fuzzel`, `mako`, `hyprlock`, `hypridle`,
`awww`, `grimblast`, `kitty`, `cliphist`, `wl-clipboard`, `wf-recorder`, `hyprpicker`,
`blueman`, `networkmanagerapplet`, `hyprlandPlugins.hy3`,
`hyprlandPlugins.borders-plus-plus` — all resolved from the existing `nixpkgs` flake input
(see `research.md`); home-manager's `wayland.windowManager.hyprland` module

**Storage**: N/A — declarative configuration only, no application data

**Testing**: `nix flake check` plus `nixos-rebuild build`/`dry-activate` for the `laptop`
host (Constitution Principle IV); manual validation walkthrough in `quickstart.md` against
the acceptance scenarios in `spec.md`

**Target Platform**: NixOS laptop host (`x86_64-linux`), Intel integrated graphics, Wayland
session via SDDM

**Project Type**: Declarative desktop-environment configuration (NixOS + home-manager
modules) — not an application with its own build/test toolchain

**Performance Goals**: Session usable within 30s of login (SC-001); compositor interactions
(window move/resize/switch) feel immediate — governed by Hyprland's own compositing, no
additional performance engineering in scope

**Constraints**: Must remain fully declarative with no imperative setup steps (Constitution
Principle I, spec FR-011); must not modify or replace the existing Plasma 6 session
(spec FR-001); must not add a new flake input (Constitution Principle II/V, research.md #1)

**Scale/Scope**: Single host (`laptop`), single user (`dmiller`); six new concern modules
(one NixOS, five home-manager) per the Structure Decision below

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Declarative Configuration Only | PASS | Every capability (session registration, bar, launcher, theming, nice-to-haves, plugins) is expressed through NixOS/home-manager options in versioned modules; FR-011 makes this an explicit requirement. |
| II. Reproducibility & Pinned Inputs | PASS | No new flake input added (research.md #1); everything resolves from the already-pinned `nixpkgs`, so `flake.lock` is untouched by this feature. |
| III. Host Modularity & Composability | PASS | New modules are host-agnostic (`modules/nixos/hyprland.nix`, `modules/home/*.nix`) and only wired in via `hosts/laptop/configuration.nix` / `modules/home/dmiller.nix`, matching the existing `desktop.nix`/`shell.nix` pattern — a future second host could opt in by importing the same modules. |
| IV. Build & Validate Before Merge | PASS (procedural) | `quickstart.md` step 1 mandates `nix flake check` + `nixos-rebuild build`/`switch` before any other validation; enforced at implementation/tasks time, not by the plan itself. |
| V. Simplicity & Incremental Change | PASS | No abstraction layer for "multiple desktop environments" is introduced — Hyprland is wired directly into the one real host (`laptop`), same as Plasma is today; six modules split along the same one-concern-per-file convention already used in `modules/home/README.md`, not a deeper or novel structure. |
| VI. Secure by Default | PASS | Adds a default auto-lock (`hypridle`+`hyprlock`, spec FR-005) rather than removing one; no new open network services or weakened auth introduced. Pre-existing SSH password-auth violation (`modules/nixos/remote-dev.nix`) is unrelated and out of scope for this feature. |
| Secrets Management | N/A | No secrets are introduced by this feature. |

No violations — Complexity Tracking table is not needed.

## Project Structure

### Documentation (this feature)

```text
specs/004-hyprland-desktop/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   ├── module-interface.md
│   └── keybindings.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

This repository has no `src`/app layout — it is a NixOS flake configuration, and its
existing structure (`modules/nixos/*.nix`, `modules/home/*.nix`, one concern per file,
wired in by `hosts/<name>/configuration.nix`) is reused as-is.

```text
modules/nixos/
├── desktop.nix           # EXISTING, unmodified (Plasma 6 / SDDM) — FR-001 fallback
└── hyprland.nix           # NEW: programs.hyprland.enable, XDG portal wiring, bluetooth

modules/home/
├── theme.nix               # NEW: shared Catppuccin Mocha palette/font/corner-radius
├── hyprland.nix             # NEW: wayland.windowManager.hyprland (binds, monitors,
│                             #      animations, window rules, plugins)
├── waybar.nix               # NEW: status bar + extra widgets
├── hypr-shell.nix           # NEW: launcher, notifications, lock/idle, wallpaper,
│                             #      screenshot, terminal (baseline sane defaults)
└── hypr-extras.nix          # NEW: clipboard, screen recording, color picker,
                              #      Bluetooth/network tray applets (nice-to-haves)

hosts/laptop/configuration.nix   # MODIFIED: import modules/nixos/hyprland.nix
modules/home/dmiller.nix          # MODIFIED: import the five new modules/home/*.nix files
modules/nixos/README.md           # MODIFIED: add hyprland.nix row (existing convention)
modules/home/README.md            # MODIFIED: add the five new module rows (existing convention)
```

**Structure Decision**: Reuse the existing "one concern per host-agnostic module file"
pattern rather than inventing a new structure. Six new files total (one `modules/nixos/`,
five `modules/home/`) map directly to the module interface documented in
`contracts/module-interface.md`, keeping each file traceable to specific FRs
(`data-model.md` records the FR mapping per module). No subdirectory nesting or abstraction
layer is introduced — consistent with Constitution Principle V and the precedent already set
by `dev-tools.nix` bundling a whole toolchain's packages under one concern.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

Not applicable — no Constitution Check violations (see table above).
