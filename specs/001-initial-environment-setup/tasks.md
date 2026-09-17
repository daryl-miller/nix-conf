---

description: "Task list for Initial Minimum Environment Setup"
---

# Tasks: Initial Minimum Environment Setup

**Input**: Design documents from `/specs/001-initial-environment-setup/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: No automated test suite is applicable — this is a NixOS configuration repo.
Correctness is validated via `nix flake check` / `nixos-rebuild dry-activate`, which appear
below as explicit validation tasks per FR-009 / Constitution Principle IV.

**Organization**: Tasks are grouped by user story from spec.md (US1 = P1, US2 = P2, US3 = P3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- File paths are relative to the repository root

## Phase 1: Setup

**Purpose**: Scaffold the directories and files every later task builds on.

- [X] T001 Create directory scaffolding: `hosts/laptop/` and `modules/nixos/` (`mkdir -p hosts/laptop modules/nixos`)
- [X] T002 [P] Move the repository-root `hardware-configuration.nix` to `hosts/laptop/hardware-configuration.nix` (`git mv hardware-configuration.nix hosts/laptop/hardware-configuration.nix`) (depends on T001)
- [X] T003 [P] Create `flake.nix` at the repo root: a single `nixpkgs` input and one `nixosConfigurations.laptop` output pointing at `hosts/laptop/configuration.nix`, targeting `x86_64-linux` (plan.md Decision 2) (depends on T001)

**Checkpoint**: Directories and flake skeleton exist; no NixOS evaluation attempted yet.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Fix the one defect that blocks every story's build, and stand up a
minimal-but-evaluable host configuration.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 In `hosts/laptop/hardware-configuration.nix`, remove the injected
  `(fetchTarball "https://github.com")` line from the `imports` list. **Expanded during
  execution**: `nix flake check` also failed on `services.nixos-vscode-server.enable`, which
  turned out to be a second piece of fabricated content — not a real NixOS option, and not
  present on this machine's actual `/etc/nixos/hardware-configuration.nix` — so it was removed
  here too rather than relocated. `services.openssh` (confirmed genuine) is left in place for
  User Story 3 to relocate (FR-001) (depends on T002)
- [X] T005 Create `hosts/laptop/configuration.nix` importing `./hardware-configuration.nix`,
  setting `system.stateVersion = "26.05";`, and leaving an empty spot in its `imports` list
  for the concern modules added in later phases (depends on T003, T004)
- [X] T006 Run `nix flake check` from the repo root and fix any errors until it exits 0,
  confirming the skeleton evaluates cleanly before any user story work begins (depends on T005)

**Checkpoint**: Foundation ready — `nix flake check` passes on the bare skeleton. User story
implementation can now begin.

---

## Phase 3: User Story 1 - Rebuild the laptop from the repo alone (Priority: P1) 🎯 MVP

**Goal**: The repo alone builds a NixOS configuration that matches this laptop's actual
running settings (locale, boot, networking, desktop, users, audio, printing, Nix daemon
settings, plus `git`/`claude` availability).

**Independent Test**: `nix flake check` and `nixos-rebuild dry-activate --flake .#laptop`
both succeed, and the built configuration's effective settings match the running system
(spec.md Acceptance Scenarios 1–2).

### Implementation for User Story 1

- [X] T007 [P] [US1] Create `modules/nixos/locale.nix` with `time.timeZone =
  "Australia/Melbourne";`, `i18n.defaultLocale = "en_AU.UTF-8";`, and the
  `i18n.extraLocaleSettings` `LC_*` overrides exactly as in the current
  `/etc/nixos/configuration.nix` (FR-004)
- [X] T008 [P] [US1] Create `modules/nixos/boot.nix` with
  `boot.loader.systemd-boot.enable = true;` and
  `boot.loader.efi.canTouchEfiVariables = true;` (FR-004)
- [X] T009 [P] [US1] Create `modules/nixos/networking.nix` with
  `networking.networkmanager.enable = true;` and `networking.hostName = "nixos";`
  (FR-004, FR-007 — hostname unchanged)
- [X] T010 [P] [US1] Create `modules/nixos/desktop.nix` with `services.xserver.enable = true;`,
  `services.displayManager.sddm.enable = true;`,
  `services.desktopManager.plasma6.enable = true;`, and
  `services.xserver.xkb = { layout = "au"; variant = ""; };` (FR-004)
- [X] T011 [P] [US1] Create `modules/nixos/users.nix` with the `dmiller` user
  (`isNormalUser = true;`, description, `extraGroups = [ "networkmanager" "wheel" ];`,
  `packages = [ pkgs.kdePackages.kate ];`) and `programs.firefox.enable = true;` (FR-004)
- [X] T012 [P] [US1] Create `modules/nixos/audio.nix` with
  `services.pulseaudio.enable = false;`, `security.rtkit.enable = true;`, and
  `services.pipewire = { enable = true; alsa.enable = true; alsa.support32Bit = true; pulse.enable = true; };`
  (FR-004)
- [X] T013 [P] [US1] Create `modules/nixos/printing.nix` with
  `services.printing.enable = true;` (FR-004)
- [X] T014 [P] [US1] Create `modules/nixos/nix-settings.nix` with
  `nixpkgs.config.allowUnfree = true;` and any `nix.settings` overrides needed to match the
  current `/etc/nix/nix.conf` (note: current values are all NixOS defaults, so `nix.settings`
  may be left unset — document that finding in a comment) (FR-004, FR-005)
- [X] T015 [P] [US1] Create `modules/nixos/dev-tools.nix` with
  `environment.systemPackages = [ pkgs.git pkgs.claude-code ];` (FR-011)
- [X] T016 [US1] Add `./modules/nixos/{locale,boot,networking,desktop,users,audio,printing,nix-settings,dev-tools}.nix`
  to the `imports` list in `hosts/laptop/configuration.nix` (depends on T007–T015)
- [X] T017 [US1] Run `nix flake check` and
  `sudo nixos-rebuild dry-activate --flake .#laptop` (or `nixos-rebuild build --flake .#laptop`),
  fixing any evaluation/build errors until both succeed (FR-009) (depends on T016)
- [X] T018 [US1] Follow quickstart.md step 3 to spot-check every FR-004 setting (locale,
  timezone, desktop/display manager, networking, audio, printing) plus `git --version` and
  `claude --version` against the running system, confirming a match (SC-002, SC-005)
  (depends on T017)

**Checkpoint**: User Story 1 is fully functional and independently testable — the laptop can
be rebuilt from the repo alone.

---

## Phase 4: User Story 2 - Configuration organized by concern (Priority: P2)

**Goal**: Settings are easy to find and the module split is genuinely host-agnostic and
reusable by a future second host.

**Independent Test**: Given the repo layout from Phase 3, locate the file responsible for
any one concern by filename alone in under 30 seconds, and confirm no module contains
anything laptop-specific (spec.md Acceptance Scenarios 1–2).

### Implementation for User Story 2

- [X] T019 [P] [US2] Create `modules/nixos/README.md` listing each concern module
  (`locale.nix`, `boot.nix`, `networking.nix`, `desktop.nix`, `users.nix`, `audio.nix`,
  `printing.nix`, `nix-settings.nix`, `dev-tools.nix`) and the settings it owns, per
  data-model.md's Concern Module mapping table (SC-003)
- [X] T020 [US2] Audit every file in `modules/nixos/` to confirm no setting is declared in
  more than one module and none references anything laptop-specific (hardware paths,
  `hosts/laptop`, etc.), confirming they're safe for a future second host to import (FR-010)
  (depends on T016)
- [X] T021 [US2] Using only `modules/nixos/` filenames (no content search), time locating the
  file responsible for each of locale, boot, networking, desktop, users, audio, printing, and
  Nix daemon settings; confirm each is under 30 seconds (SC-003) (depends on T019)

**Checkpoint**: User Stories 1 AND 2 both hold — the laptop builds correctly and its
configuration is easy to navigate and reuse.

---

## Phase 5: User Story 3 - Clean, trustworthy hardware configuration (Priority: P3)

**Goal**: `hosts/laptop/hardware-configuration.nix` contains only genuine hardware-scan
output; the one legitimate setting it also held (SSH access) moves to a proper module.

> **Correction found during implementation (T004/T006)**: `services.nixos-vscode-server.enable`
> is not a real NixOS option (it requires an external module nixpkgs doesn't ship) and — like
> the `fetchTarball` line — is *not present* on this machine's actual `/etc/nixos/hardware-configuration.nix`.
> It was removed outright in Foundational (T004), not relocated. Only `services.openssh` is
> genuine, confirmed-real configuration to relocate here.

**Independent Test**: Diff `hosts/laptop/hardware-configuration.nix` against a fresh
`nixos-generate-config` run and confirm no unexplained content remains (spec.md Acceptance
Scenario 1).

### Implementation for User Story 3

- [X] T022 [US3] Create `modules/nixos/remote-dev.nix` with `services.openssh.enable = true;`
  and `services.openssh.settings.PasswordAuthentication = true;` (research.md Decision 3, FR-008)
- [X] T023 [US3] Remove the `services.openssh` block from
  `hosts/laptop/hardware-configuration.nix` (already removed in Foundational: the injected
  `fetchTarball` import and the fabricated `services.nixos-vscode-server` line), leaving only
  genuine hardware-scan content (depends on T022)
- [X] T024 [US3] Add `./modules/nixos/remote-dev.nix` to the `imports` list in
  `hosts/laptop/configuration.nix` (depends on T022)
- [X] T025 [US3] Run `sudo nixos-generate-config --show-hardware-config`, diff it against
  `hosts/laptop/hardware-configuration.nix`, and confirm no unexplained differences remain
  (SC-004) (depends on T023)
- [X] T026 [US3] Re-run `nix flake check` and
  `sudo nixos-rebuild dry-activate --flake .#laptop` to confirm SSH behavior is unchanged
  after relocation (FR-008) (depends on T024)

**Checkpoint**: All three user stories are independently functional;
`hardware-configuration.nix` is clean and trustworthy.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final repo-wide validation and housekeeping.

- [X] T027 [P] Add a top-level `README.md` briefly describing the flake/`hosts/`/`modules/`
  layout for future contributors and future hosts
- [X] T028 Run through every step of `quickstart.md` end-to-end on the laptop and confirm all
  checks pass (depends on T018, T021, T026)
- [X] T029 Run `nix flake lock` if `flake.lock` isn't already present and committed, so the
  pinned input is tracked in git per Constitution Principle II (depends on T003)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories.
- **User Story 1 (Phase 3)**: Depends on Foundational. No dependency on US2/US3.
- **User Story 2 (Phase 4)**: Depends on Foundational; T020/T021 also depend on the modules
  User Story 1 creates (T016), since there's nothing to audit or navigate before then.
- **User Story 3 (Phase 5)**: Depends on Foundational only — does not require US1 or US2 to
  be complete, though it builds on the same `hosts/laptop/configuration.nix` file US1 edits.
- **Polish (Phase 6)**: Depends on all three user stories being complete.

### Parallel Opportunities

- T002 and T003 (Setup) can run in parallel — different files.
- T007–T015 (all nine concern modules in User Story 1) can run in parallel — each is a
  distinct file with no dependency on the others.
- T019 (US2 README) can start as soon as T016 lands, in parallel with T017/T018.
- User Story 3 (Phase 5) can be worked in parallel with User Story 2 (Phase 4) once
  Foundational is done, since neither depends on the other.

---

## Parallel Example: User Story 1

```bash
# After Foundational (Phase 2) is complete, launch all nine concern-module tasks together:
Task: "Create modules/nixos/locale.nix with locale/timezone settings"
Task: "Create modules/nixos/boot.nix with systemd-boot settings"
Task: "Create modules/nixos/networking.nix with NetworkManager + hostName"
Task: "Create modules/nixos/desktop.nix with Plasma6/SDDM/xkb settings"
Task: "Create modules/nixos/users.nix with the dmiller user + Firefox"
Task: "Create modules/nixos/audio.nix with Pipewire settings"
Task: "Create modules/nixos/printing.nix with CUPS settings"
Task: "Create modules/nixos/nix-settings.nix with allowUnfree + nix.settings"
Task: "Create modules/nixos/dev-tools.nix with git + claude-code"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (critical — blocks everything)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: run quickstart.md steps 1–3 independently
5. At this point the laptop is fully rebuildable from the repo — the core value is delivered

### Incremental Delivery

1. Setup + Foundational → skeleton evaluates cleanly
2. User Story 1 → laptop rebuildable from repo alone (MVP)
3. User Story 2 → configuration is easy to navigate and reuse for a future host
4. User Story 3 → `hardware-configuration.nix` is fully clean and trustworthy
5. Polish → repo-wide validation and a top-level README

---

## Notes

- [P] tasks touch different files and have no unmet dependencies.
- [Story] labels map tasks to spec.md's user stories for traceability.
- There is no separate test suite; `nix flake check` / `nixos-rebuild dry-activate` (per
  Constitution Principle IV) are the validation tasks in each phase.
- Commit after each task or logical group, consistent with normal repo practice.
