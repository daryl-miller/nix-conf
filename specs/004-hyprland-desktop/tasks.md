---

description: "Task list for Hyprland Desktop Environment"
---

# Tasks: Hyprland Desktop Environment

**Input**: Design documents from `/specs/004-hyprland-desktop/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Not requested in the feature spec. Validation is done via `nix flake check` /
`nixos-rebuild build` (Constitution Principle IV) and the manual walkthrough in
`quickstart.md`, not automated test suites — this repo has no test framework for
declarative Nix configuration.

**Organization**: Tasks are grouped by user story (US1/US2 are tied P1, US3 is P2) per
`spec.md`. `modules/home/hypr-shell.nix` and `modules/home/hypr-extras.nix` are each a
single file per the plan's Structure Decision, so tasks that edit the same file within a
story are sequential even when unmarked `[P]`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is a NixOS flake configuration, not an app — there is no `src`/`tests` tree. All paths
are relative to the repository root, following the existing `modules/nixos/*.nix` /
`modules/home/*.nix` one-concern-per-file convention (see `plan.md` Structure Decision).

---

## Phase 1: Setup

**Purpose**: Confirm the package names this plan relies on actually exist in the pinned
`nixpkgs` before building anything on top of them.

- [X] T001 Verify the exact `nixpkgs` attribute paths for every package in plan.md's Primary
      Dependencies list (`hyprland`, `waybar`, `fuzzel`, `mako`, `hyprlock`, `hypridle`,
      `awww`, `grimblast`, `kitty`, `cliphist`, `wl-clipboard`, `wf-recorder`, `hyprpicker`,
      `blueman`, `networkmanagerapplet`, `playerctl`, `hyprlandPlugins.hy3`,
      `hyprlandPlugins.borders-plus-plus`) via `nix search nixpkgs <name>` /
      `nix eval .#nixosConfigurations.laptop.pkgs.<attr>`; correct any mismatched attribute
      path in `specs/004-hyprland-desktop/research.md` before continuing.

**Checkpoint**: Every package name used by later tasks is confirmed to resolve.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The shared theme and the system-level session registration that every user
story's modules build on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] Create `modules/home/theme.nix` exporting the Catppuccin Mocha palette, font,
      corner-radius, and animation-curve attrset described in `data-model.md`'s Theme entity
      (research.md #10)
- [X] T003 [P] Create `modules/nixos/hyprland.nix` with `programs.hyprland.enable = true`,
      `xdg-desktop-portal-hyprland` wired as the active portal, `hardware.bluetooth.enable =
      true`, and `services.blueman.enable = true` (required system-wide by the home-manager
      `services.blueman-applet` used in US3) (research.md #1, #2; data-model.md System
      Session)
- [X] T004 Import `modules/nixos/hyprland.nix` in `hosts/laptop/configuration.nix`, alongside
      the existing (untouched) `modules/nixos/desktop.nix` import (depends on: T003)
- [X] T005 Run `nix flake check` from the repo root to confirm the new modules evaluate
      cleanly before building out user-story configuration (depends on: T002, T004)

**Checkpoint**: Foundation ready — theme and system session registration exist; user story
implementation can now begin.

---

## Phase 3: User Story 1 - Log in to a working Hyprland session (Priority: P1) 🎯 MVP

**Goal**: Selecting the Hyprland session at login produces a working desktop — bar,
wallpaper, and the core window-management keybindings (terminal, launcher, workspaces,
move/resize, close) all function with zero manual configuration.

**Independent Test**: On a freshly rebuilt system, select Hyprland at the SDDM login screen
and confirm the compositor starts, a status bar and wallpaper are visible, and every binding
in `contracts/keybindings.md` for terminal/launcher/workspace/move/resize/close works.

### Implementation for User Story 1

- [X] T006 [P] [US1] Create `modules/home/hyprland.nix` enabling
      `wayland.windowManager.hyprland`, with `bindings` for open-terminal, open-launcher,
      close-window, switch-workspace, move-window-to-workspace, and move/resize-window
      (contracts/keybindings.md), plus `monitors` and baseline `windowRules`/`animations`
      sourced from `modules/home/theme.nix` (depends on: T002)
- [X] T007 [P] [US1] Create `modules/home/waybar.nix` with `programs.waybar` configured to
      show the active workspace, clock, network, battery, and volume (spec FR-003), styled
      from `modules/home/theme.nix` (depends on: T002)
- [X] T008 [P] [US1] Create `modules/home/hypr-shell.nix` with a `programs.kitty` terminal
      section using the Catppuccin Mocha theme from `modules/home/theme.nix` (depends on: T002)
- [X] T009 [US1] Add a `programs.fuzzel` application-launcher section to
      `modules/home/hypr-shell.nix` (spec FR-004) (depends on: T008)
- [X] T010 [US1] Add an `awww`-backed wallpaper service plus a default wallpaper asset to
      `modules/home/hypr-shell.nix` (spec FR-006) (depends on: T009)
- [X] T011 [US1] Wire the open-terminal and open-launcher bindings in
      `modules/home/hyprland.nix` to invoke `kitty` / `fuzzel` from T008/T009
      (depends on: T006, T008, T009)
- [X] T012 [US1] Import `modules/home/hyprland.nix`, `modules/home/waybar.nix`, and
      `modules/home/hypr-shell.nix` in `modules/home/dmiller.nix`
      (depends on: T006, T007, T010, T011)
- [X] T013 [US1] Validate: `nix flake check` and `sudo nixos-rebuild build --flake .#laptop`
      succeed, then run `quickstart.md` steps 1–2 and step 3 items 1–6 (terminal, launcher,
      bar, workspace switch/move, window move/resize, close window) (depends on: T012)

**Checkpoint**: User Story 1 is fully functional and independently testable — a working
Hyprland session with bar, wallpaper, and core window management.

---

## Phase 4: User Story 2 - Work day-to-day without missing basic desktop conveniences (Priority: P1)

**Goal**: The session auto-locks on idle, can be locked/screenshotted on demand, and shows
application notifications — the remaining "sane defaults" beyond raw window management.

**Independent Test**: On a freshly rebuilt system, confirm the session auto-locks after the
configured inactivity period, the manual lock keybinding works, the screenshot keybindings
capture full-screen and a selected region, and a test notification is displayed.

### Implementation for User Story 2

- [X] T014 [US2] Add a `services.mako` notification-daemon section, themed from
      `modules/home/theme.nix`, to `modules/home/hypr-shell.nix` (spec FR-008)
      (depends on: T010)
- [X] T015 [US2] Add a `programs.hyprlock` lock-screen section, themed from
      `modules/home/theme.nix`, to `modules/home/hypr-shell.nix` (spec FR-005)
      (depends on: T014)
- [X] T016 [US2] Add a `services.hypridle` section to `modules/home/hypr-shell.nix` that
      triggers `hyprlock` after a configured inactivity timeout (spec FR-005)
      (depends on: T015)
- [X] T017 [US2] Add the `grimblast` package plus full-screen and region-select screenshot
      keybinding wiring to `modules/home/hypr-shell.nix` (spec FR-007) (depends on: T016)
- [X] T018 [US2] Add the manual-lock and both screenshot bindings from
      `contracts/keybindings.md` to `modules/home/hyprland.nix`, invoking `hyprlock` /
      `grimblast` from T015/T017 (depends on: T006, T017)
- [X] T019 [US2] Validate: `sudo nixos-rebuild build --flake .#laptop` succeeds, then run
      `quickstart.md` step 3 items 7–10 (full-screen screenshot, region screenshot, manual
      lock, idle auto-lock, test notification) (depends on: T018)

**Checkpoint**: User Stories 1 and 2 both work independently — the full "sane defaults"
baseline (spec FR-001–FR-008, FR-011) is complete.

---

## Phase 5: User Story 3 - Choose which nice-to-have companion tools to include (Priority: P2)

**Goal**: All of the developer's selected nice-to-have tools (clipboard history, screen
recording, color picker, extra bar widgets, Bluetooth/network tray applets, and the two
Hyprland plugins) are present and functional, and nothing beyond that list is installed.

**Independent Test**: Review `spec.md` FR-009's selected list, then confirm each item is
present and functional after rebuild, per `quickstart.md` step 4.

### Implementation for User Story 3

- [X] T020 [P] [US3] Create `modules/home/hypr-extras.nix` with `services.cliphist.enable =
      true` + `wl-clipboard` clipboard-history config and a keybinding piping `cliphist list`
      through `fuzzel --dmenu` (spec FR-009) (depends on: T002)
- [X] T021 [US3] Add the `wf-recorder` package plus start/stop screen-recording keybinding
      wiring to `modules/home/hypr-extras.nix` (spec FR-009) (depends on: T020)
- [X] T022 [US3] Add the `hyprpicker` package plus a color-picker keybinding to
      `modules/home/hypr-extras.nix` (spec FR-009) (depends on: T021)
- [X] T023 [US3] Add `services.blueman-applet.enable = true` and
      `services.network-manager-applet.enable = true` to `modules/home/hypr-extras.nix`
      (spec FR-009) (depends on: T022)
- [X] T024 [US3] Add `mpris` (backed by `services.playerctld.enable = true`), `cpu`,
      `memory`, `temperature`, and `tray` modules to `modules/home/waybar.nix` so the
      Bluetooth/network applets from T023 and media controls are visible (spec FR-009)
      (depends on: T007, T023)
- [X] T025 [US3] Add `hy3` and `borders-plus-plus` plugin declarations (verified
      attribute paths from T001) to `wayland.windowManager.hyprland.plugins` in
      `modules/home/hyprland.nix`, plus a workspace-overview keybinding (spec FR-009)
      (depends on: T001, T006)
- [X] T026 [US3] Import `modules/home/hypr-extras.nix` in `modules/home/dmiller.nix`
      (depends on: T012, T023)
- [X] T027 [US3] Validate: `sudo nixos-rebuild build --flake .#laptop` succeeds, then run
      `quickstart.md` step 4 in full (clipboard history, screen recording, color picker,
      extra bar widgets, tray applets, `hy3`/`borders-plus-plus`) (depends on: T024,
      T025, T026)

**Checkpoint**: All three user stories are independently functional — the full feature is
complete (spec FR-001–FR-011).

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation upkeep and the final end-to-end gate.

- [X] T028 [P] Add a `hyprland.nix` row to `modules/nixos/README.md`'s settings table,
      matching the existing convention (depends on: T003)
- [X] T029 [P] Add rows for `theme.nix`, `hyprland.nix`, `waybar.nix`, `hypr-shell.nix`, and
      `hypr-extras.nix` to `modules/home/README.md`'s settings table (depends on: T025,
      T017, T024, T026)
- [ ] T030 Run the full `quickstart.md` walkthrough end-to-end (steps 1–5), confirming Plasma
      still boots unmodified (spec SC-005) and SC-001–SC-004 all hold (depends on: T013,
      T019, T027)
      **Partially done**: step 1 (`nix flake check` + full `nixosConfigurations.laptop`
      build) passed, and static checks confirmed both session entries are registered
      (`services.displayManager.sessionPackages` = `[plasma-workspace hyprland]`), Plasma's
      own options are untouched, and every planned package resolves in the built closure.
      Steps 2–4 (actually logging into SDDM, pressing keybindings, and eyeballing the
      bar/lock/wallpaper/notifications/plugins) require a real display and were **not**
      run — no GUI access in this environment. The developer must run
      `sudo nixos-rebuild switch --flake .#laptop` and do the interactive walkthrough
      themselves before checking this task off.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup (T001) confirming package names — blocks all
  user stories.
- **User Stories (Phase 3–5)**: All depend on Foundational (Phase 2) completion.
  - US1 and US2 both touch `modules/home/hypr-shell.nix` and `modules/home/hyprland.nix`
    sequentially (same files), so in practice implement US1 then US2 in order even though
    both are P1.
  - US3 edits `modules/home/waybar.nix` (T024) and `modules/home/hyprland.nix` (T025), which
    US1 created — those two tasks can only start once T007/T006 exist, but `hypr-extras.nix`
    itself (T020–T023) only depends on Foundational and can be built in parallel with US2.
- **Polish (Phase 6)**: Depends on all three user stories being complete.

### Within Each User Story

- `hypr-shell.nix` and `hypr-extras.nix` are each built up by a sequence of tasks that edit
  the same file — these are intentionally *not* marked `[P]` even though no other task
  literally blocks them, to avoid concurrent edits to one file.
- Each story's final task is a rebuild + `quickstart.md` validation, matching Constitution
  Principle IV (build & validate before merge) applied per increment, not just once at the
  end.

### Parallel Opportunities

- Foundational: T002 and T003 (different files).
- US1: T006, T007, and T008 (three different new files) once Foundational is done.
- US3: T020 (`hypr-extras.nix`) can start as soon as Foundational is done, in parallel with
  all of US2's `hypr-shell.nix` edits (different files).
- Polish: T028 and T029 (different README files).

---

## Parallel Example: Foundational → User Story 1

```bash
# Foundational, in parallel:
Task: "Create modules/home/theme.nix exporting the Catppuccin Mocha palette/font/radius/animation attrset"
Task: "Create modules/nixos/hyprland.nix enabling programs.hyprland, xdg portal, bluetooth"

# Once Foundational completes, start of User Story 1, in parallel:
Task: "Create modules/home/hyprland.nix with core window-management bindings"
Task: "Create modules/home/waybar.nix with workspace/clock/network/battery/volume modules"
Task: "Create modules/home/hypr-shell.nix with the kitty terminal section"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (confirm package names).
2. Complete Phase 2: Foundational (theme + system session registration).
3. Complete Phase 3: User Story 1.
4. **STOP and VALIDATE**: run `quickstart.md` steps 1–3 (items 1–6) independently.
5. This alone is a demoable, loggable-into Hyprland session with a bar, wallpaper, and core
   window management — a real MVP even before locking/notifications/nice-to-haves exist.

### Incremental Delivery

1. Setup + Foundational → theme and session registration ready.
2. Add User Story 1 → validate independently → MVP.
3. Add User Story 2 → validate independently → full "sane defaults" baseline complete.
4. Add User Story 3 → validate independently → all selected nice-to-haves present.
5. Polish → documentation rows added, full end-to-end `quickstart.md` run, Plasma regression
   check.

---

## Phase 7: Convergence

Findings from a `/speckit-converge` pass against the implemented code.

- [ ] T031 Switch the screenshot bindings in `modules/home/hypr-shell.nix` from `grimblast
      copy screen` / `grimblast copy area` to `grimblast copysave screen` / `grimblast
      copysave area` so a file is actually saved (currently `copy` only puts the image on
      the clipboard, contradicting `quickstart.md`'s "confirm both files are produced"
      validation for T017/T019) per FR-007 (contradicts)
- [ ] T032 Install a Nerd Font package (e.g. `pkgs.nerd-fonts.jetbrains-mono`, confirmed
      present in the pinned `nixpkgs`) so `hyprTheme.font = "JetBrainsMono Nerd Font"`
      (`modules/home/theme.nix`), referenced by `waybar.nix`, `hypr-shell.nix`'s kitty/
      fuzzel/mako config, actually resolves instead of silently falling back and rendering
      every Nerd Font glyph (workspace/network/battery/cpu/tray icons) as tofu per FR-010,
      SC-003 (missing)

---

## Notes

- `[P]` tasks = different files, no dependencies on incomplete tasks.
- `[Story]` label maps each task to a specific user story for traceability back to `spec.md`.
- No test-framework tasks are included — this feature's "tests" are the `nix flake check` /
  `nixos-rebuild build` gate (Constitution Principle IV) plus the manual `quickstart.md`
  walkthrough, run as validation tasks at the end of each story (T013, T019, T027) and once
  more end-to-end (T030).
- Commit after each task or logical group.
- Stop at any checkpoint to validate a story independently before continuing.
