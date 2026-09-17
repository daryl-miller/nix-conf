---

description: "Task list for Developer Environment Tooling"
---

# Tasks: Developer Environment Tooling

**Input**: Design documents from `/specs/003-dev-environment-tooling/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md (all present)

**Tests**: Not requested in the feature specification — this is Nix system/user
configuration; validation is via `nix flake check` / dry-build / quickstart.md, not a test
suite. No test tasks are included.

**Organization**: Tasks are grouped by user story (from spec.md: US1–US4, priority order
P1–P4) to enable independent implementation and validation of each.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story this task belongs to (US1–US4)
- File paths are exact and relative to the repository root

## Path Conventions

Single Nix flake configuration repository (see plan.md Project Structure):
`flake.nix`, `hosts/laptop/`, `modules/nixos/`, `modules/home/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Bring in the one new dependency (`home-manager`) this feature needs, before any
module can reference it.

- [X] T001 In `flake.nix`, add the `home-manager` input (`inputs.home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };`) and add `home-manager.nixosModules.home-manager` to the `modules` list of the `nixosConfigurations.laptop` `nixosSystem` call, passing `home-manager` through the `outputs` function arguments.
- [X] T002 Run `nix flake lock` (or `nix flake check`, which relocks automatically) at the repo root to fetch and pin `home-manager` into the committed `flake.lock`.

**Checkpoint**: `home-manager.nixosModules.home-manager` is available to import; `flake.lock` includes a pinned `home-manager` entry.

---

## Phase 2: Foundational (Home-Manager Wiring)

**Purpose**: Stand up the per-user (home-manager) configuration tier so User Stories 2 and 3
have somewhere to attach their settings.

**⚠️ Scope note**: This phase blocks **User Story 2 and User Story 3 only**. **User Story 1**
(system toolchains) and **User Story 4** (VS Code Server / `nix-ld`) are purely system-level,
do not touch home-manager at all, and MAY be implemented and validated in parallel with — or
even before — this phase.

- [X] T003 Create `modules/home/dmiller.nix` with `{ ... }: { home.username = "dmiller"; home.homeDirectory = "/home/dmiller"; home.stateVersion = "26.05"; imports = [ ]; }` (per data-model.md Home Configuration; the `imports` list is populated by US2/US3 tasks below).
- [X] T004 Create `modules/nixos/home-manager.nix` with `home-manager.useGlobalPkgs = true;`, `home-manager.useUserPackages = true;`, and `home-manager.users.dmiller = import ../home/dmiller.nix;` (depends on T003 existing).
- [X] T005 Add `../../modules/nixos/home-manager.nix` to the `imports` list in `hosts/laptop/configuration.nix` (depends on T004).

**Checkpoint**: `nix flake check` evaluates a (currently empty) `home-manager.users.dmiller` generation with no errors.

---

## Phase 3: User Story 1 - Work across the full toolchain without manual installs (Priority: P1) 🎯 MVP

**Goal**: .NET SDK, AWS CLI, Terraform, Docker, Node.js, and Python are all on `PATH` for
`dmiller` after a rebuild, with Docker usable without `sudo`.

**Independent Test**: Per quickstart.md §3 — on a freshly rebuilt system, open a new shell
and run `dotnet --version`, `aws --version`, `terraform -version`, `docker run --rm
hello-world`, `node --version`, `python3 --version`; all succeed with no `sudo` and no
further install step.

### Implementation for User Story 1

- [X] T006 [P] [US1] In `modules/nixos/dev-tools.nix`, add `dotnet-sdk`, `dotnet-aspnetcore`, `dotnet-ef`, `csharpier`, `go`, `awscli2`, `aws-sso-cli`, `terraform`, `nodejs`, and `python3` to `environment.systemPackages`, and add `virtualisation.docker.enable = true;` (per research.md Decision 2).
- [X] T007 [P] [US1] In `modules/nixos/users.nix`, add `"docker"` to `users.users.dmiller.extraGroups` (alongside the existing `networkmanager`/`wheel`).
- [X] T008 [US1] Dry-build and validate: run `nix flake check` then `sudo nixos-rebuild dry-activate --flake .#laptop` (depends on T006, T007); after switching, run quickstart.md §3 and confirm every command succeeds with no `sudo`.

**Checkpoint**: User Story 1 is fully functional and independently testable — this alone is a shippable MVP.

---

## Phase 4: User Story 2 - Productive daily shell (Priority: P2)

**Goal**: `dmiller`'s default shell is zsh with fuzzy search (`fzf`) and autosuggestions/syntax-highlighting/completion active.

**Independent Test**: Per quickstart.md §4 — open a new terminal, confirm `$SHELL` ends in
`/zsh`; Ctrl-R and Ctrl-T trigger `fzf` fuzzy search; autosuggestions and syntax highlighting
are visibly active while typing.

**Depends on**: Phase 2 (Foundational) T003–T005.

### Implementation for User Story 2

- [X] T009 [P] [US2] Create `modules/home/shell.nix` with `programs.zsh.enable = true;` (`autosuggestion.enable = true;`, `syntaxHighlighting.enable = true;`, `enableCompletion = true;`) and `programs.fzf.enable = true;` (`enableZshIntegration = true;`) (per research.md Decision 4).
- [X] T010 [US2] Add `./shell.nix` to the `imports` list in `modules/home/dmiller.nix` (depends on T009; this file is shared with User Story 3's T015 — add only the `shell.nix` line here).
- [X] T011 [US2] In `modules/nixos/users.nix`, add `programs.zsh.enable = true;` (system-wide, required for zsh to appear in `/etc/shells`) and set `users.users.dmiller.shell = pkgs.zsh;`.
- [X] T012 [US2] Dry-build and validate: run `nix flake check` then `sudo nixos-rebuild dry-activate --flake .#laptop` (depends on T010, T011); after switching, run quickstart.md §4 and confirm shell, fuzzy search, autosuggestions, and syntax highlighting all work.

**Checkpoint**: User Stories 1 and 2 both work independently.

---

## Phase 5: User Story 3 - Editing and long-lived terminal sessions (Priority: P3)

**Goal**: Neovim and tmux are available to `dmiller`; tmux sessions survive detach/reconnect.

**Independent Test**: Per quickstart.md §5 — `nvim` opens, edits, and saves a file; a tmux
session with a running process survives detach, full disconnect, and reattach.

**Depends on**: Phase 2 (Foundational) T003–T005.

### Implementation for User Story 3

- [X] T013 [P] [US3] Create `modules/home/editor.nix` with `programs.neovim.enable = true;`.
- [X] T014 [P] [US3] Create `modules/home/tmux.nix` with `programs.tmux.enable = true;`.
- [X] T015 [US3] Add `./editor.nix` and `./tmux.nix` to the `imports` list in `modules/home/dmiller.nix` (depends on T013, T014; shared file with User Story 2's T010 — if both stories are in flight together, merge the two `imports` edits rather than overwriting one another).
- [X] T016 [US3] Dry-build and validate: run `nix flake check` then `sudo nixos-rebuild dry-activate --flake .#laptop` (depends on T015); after switching, run quickstart.md §5 and confirm `nvim` and the tmux detach/reattach flow both work.

**Checkpoint**: User Stories 1, 2, and 3 all work independently.

---

## Phase 6: User Story 4 - Remote development via VS Code Server (Priority: P4)

**Goal**: VS Code's Remote-SSH extension can connect to the laptop as `dmiller` and run a
working remote session, without weakening the existing SSH posture.

**Independent Test**: Per quickstart.md §6 — from a separate machine already holding an
authorized key (per specs/002-harden-ssh-access), connect via VS Code Remote-SSH and confirm
the remote server bootstraps, file browsing/terminal/edit-save work, and an unauthorized
client still fails to connect exactly as before.

**Depends on**: Nothing from Phase 2 — this is purely system-level (`modules/nixos/remote-dev.nix`) and may be done any time after Setup.

### Implementation for User Story 4

- [X] T017 [US4] In `modules/nixos/remote-dev.nix`, add `programs.nix-ld.enable = true;` (per research.md Decision 3).
- [X] T018 [US4] Dry-build and validate: run `nix flake check` then `sudo nixos-rebuild dry-activate --flake .#laptop` (depends on T017); after switching, run quickstart.md §6 from a separate machine and confirm the remote session works and no weaker auth path was introduced (FR-008).

**Checkpoint**: All four user stories are independently functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation and final, whole-feature validation.

- [X] T019 [P] Update the module table in `modules/nixos/README.md`: revise the `dev-tools.nix` row to list the new packages and `virtualisation.docker.enable`, revise the `remote-dev.nix` row to add `programs.nix-ld.enable`, and add a new row for `home-manager.nix` (per data-model.md's System Concern Module mapping).
- [X] T020 [P] Create `modules/home/README.md` documenting the new Home Concern Module tier (mirroring `modules/nixos/README.md`'s format), listing `shell.nix`, `editor.nix`, and `tmux.nix` with the settings each owns (per data-model.md's Home Concern Module mapping).
- [X] T021 Run `nix flake check` for the complete, combined feature (depends on all of T001–T018) — the Constitution Principle IV gate for this feature as a whole.
- [ ] T022 Execute all of `quickstart.md` (§1–§7) end-to-end on the laptop and confirm SC-001 through SC-005 (depends on T021).

---

## Phase 8: Post-Plan Additions (User-Requested Mid-Implementation)

**Purpose**: Capture the requests made after the original task breakdown was generated.
Each was verified against the pinned `nixpkgs` before being added (see research.md Decisions
2, 4, 6) and folded back into spec.md/data-model.md.

- [X] T023 [P] [US1] In `modules/nixos/dev-tools.nix`, add `kubectl` and `k3d` to `environment.systemPackages` (per research.md Decision 2; `k3d` uses the Docker toolchain already enabled by T006).
- [X] T024 [P] [US2] Create `modules/home/github.nix` with `programs.gh.enable = true;` and `home.packages = [ pkgs.ghstack ];` (per research.md Decision 6).
- [X] T025 [US2] Add `./github.nix` to the `imports` list in `modules/home/dmiller.nix` (depends on T024).
- [X] T026 [US2] In `modules/home/shell.nix`, add `programs.zsh.shellAliases` (`ls`/`grep`/`diff` with `--color=auto`) and `programs.starship.enable = true;` (`enableZshIntegration = true;`) (per research.md Decision 4).
- [X] T027 Update `modules/nixos/README.md` (`dev-tools.nix` row for `kubectl`/`k3d`; `users.nix` row for `programs.zsh.enable`) and `modules/home/README.md` (`shell.nix` row for Starship/color aliases; new `github.nix` row) to match.
- [X] T028 Dry-build and validate: `nix flake check` then `nix build .#nixosConfigurations.laptop.config.system.build.toplevel` (depends on T023–T026) — all additions confirmed building successfully.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup — blocks **User Story 2 and User Story 3 only**.
- **User Story 1 (Phase 3)**: Depends only on Setup (Phase 1). Independent of Phase 2.
- **User Story 4 (Phase 6)**: Depends only on Setup (Phase 1). Independent of Phase 2.
- **User Story 2 (Phase 4)** and **User Story 3 (Phase 5)**: Depend on Foundational (Phase 2). Independent of each other and of US1/US4, except both edit `modules/home/dmiller.nix` (see T010/T015 notes).
- **Polish (Phase 7)**: Depends on all user stories being complete.

### Parallel Opportunities

- T006 and T007 (US1) — different files.
- T013 and T014 (US3) — different files.
- Once Phase 1 completes: **US1 (Phase 3) and US4 (Phase 6) can be implemented and validated fully in parallel with Phase 2, US2, and US3** — they share no files.
- T019 and T020 (Polish) — different files.
- Only real cross-story contention: `modules/home/dmiller.nix` (T010 in US2, T015 in US3) and `modules/nixos/users.nix` (T007 in US1, T011 in US2) — small, single-line-per-story additions to a shared aggregator/entrypoint file, the same pattern features 001/002 already used for `hosts/laptop/configuration.nix`.

## Parallel Example: User Story 1 (MVP)

```bash
# After Phase 1 (Setup) completes:
Task: "Add dotnet-sdk, awscli2, terraform, nodejs, python3, virtualisation.docker.enable in modules/nixos/dev-tools.nix"
Task: "Add \"docker\" to users.users.dmiller.extraGroups in modules/nixos/users.nix"
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (Setup) — needed only so `flake.lock` is settled; US1 itself doesn't use `home-manager`, but Setup is cheap and shared.
2. Complete Phase 3 (User Story 1).
3. **STOP and VALIDATE**: run quickstart.md §3 independently.
4. This is a usable, shippable increment — every requested toolchain is available.

### Incremental Delivery

1. Setup → Phase 3 (US1) → validate → MVP shipped.
2. Foundational (Phase 2) → Phase 4 (US2) → validate → productive shell shipped.
3. Phase 5 (US3, reuses Phase 2's foundation) → validate → editor/multiplexer shipped.
4. Phase 6 (US4, independent of Phase 2) → validate → remote development shipped.
5. Phase 7 → documentation + whole-feature validation.

### Suggested Order for a Single Implementer

Given the low coupling, the priority order from spec.md (P1 → P2 → P3 → P4) is also the
simplest path: T001–T002, T006–T008 (MVP), T003–T005, T009–T012, T013–T016, T017–T018,
T019–T022.
