---

description: "Task list for Chrome, Obsidian & Bitwarden Desktop Apps"
---

# Tasks: Chrome, Obsidian & Bitwarden Desktop Apps

**Input**: Design documents from `/specs/005-chrome-obsidian-bitwarden/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: No test framework applies to a declarative package addition (see `plan.md`
Technical Context → Testing). Validation instead follows Constitution Principle IV
(`nix flake check` + dry-build) plus the manual launch checks in `quickstart.md`, both
represented as explicit tasks below rather than automated tests.

**Organization**: Tasks are grouped by user story (Chrome = US1, Obsidian = US2,
Bitwarden = US3) to enable independent implementation and validation of each app.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Single NixOS flake configuration repo (see `plan.md` Project Structure):

- `modules/nixos/desktop-apps.nix` — new module holding all three packages
- `hosts/laptop/configuration.nix` — host config that imports the new module

---

## Phase 1: Setup

*No project initialization is needed — this feature edits an existing, already-building
NixOS flake configuration. Setup work is folded into Phase 2 below, since the one new file
this feature needs (`desktop-apps.nix`) is itself a blocking prerequisite for every user
story, not standalone init work.*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create the shared module and wire it into the host config that every user
story's package addition depends on.

**⚠️ CRITICAL**: No user story task can begin until this phase is complete — all three add
a package to the same file created here.

- [X] T001 Create `modules/nixos/desktop-apps.nix` with an `environment.systemPackages`
  list (initially empty, following the shape of `modules/nixos/dev-tools.nix`)
- [X] T002 Import `../../modules/nixos/desktop-apps.nix` in the `imports` list of
  `hosts/laptop/configuration.nix` (depends on T001)

**Checkpoint**: `nix flake check` succeeds with the new (empty) module wired in —
foundation ready, user story implementation can now begin.

---

## Phase 3: User Story 1 - Browse the web with Chrome (Priority: P1) 🎯 MVP

**Goal**: `dmiller` can launch Google Chrome from the desktop environment immediately
after a rebuild.

**Independent Test**: On a rebuilt system, launch Chrome from the application launcher,
confirm it loads a web page, and confirm state persists across a relaunch (spec.md User
Story 1 Acceptance Scenarios).

### Implementation for User Story 1

- [X] T003 [US1] Add `pkgs.google-chrome` to `environment.systemPackages` in
  `modules/nixos/desktop-apps.nix` (depends on T001/T002)
- [X] T004 [US1] Run `nix flake check` and
  `nixos-rebuild dry-activate --flake .#laptop`; confirm `google-chrome` appears in the
  activation diff (quickstart.md step 1) (depends on T003) — ran `nixos-rebuild dry-build`
  (equivalent evaluation/build check without an active session to diff against); exit 0
- [ ] T005 [US1] Apply with `sudo nixos-rebuild switch --flake .#laptop`, then manually
  verify: Chrome launches and loads a page, a bookmark persists across a Chrome relaunch,
  and Firefox still launches and works normally (spec.md FR-005 / Edge Cases;
  quickstart.md step 3) (depends on T004) — NOT DONE: requires the user to run `switch`
  (system-changing, needs confirmation) and manually verify GUI behavior

**Checkpoint**: Chrome is fully functional and independently verified.

---

## Phase 4: User Story 2 - Take notes with Obsidian (Priority: P2)

**Goal**: `dmiller` can launch Obsidian from the desktop environment immediately after a
rebuild and use a local Markdown vault.

**Independent Test**: On a rebuilt system, launch Obsidian, create/open a vault, create a
note, and confirm it's saved to disk as a Markdown file (spec.md User Story 2 Acceptance
Scenarios).

### Implementation for User Story 2

- [X] T006 [US2] Add `pkgs.obsidian` to `environment.systemPackages` in
  `modules/nixos/desktop-apps.nix` (depends on T001/T002; edits the same file as T003,
  so do this after T003 is committed to avoid a merge conflict)
- [X] T007 [US2] Run `nix flake check` and
  `nixos-rebuild dry-activate --flake .#laptop`; confirm `obsidian` appears in the
  activation diff (quickstart.md step 1) (depends on T006) — verified via combined
  `nixos-rebuild dry-build` (see T012); exit 0
- [ ] T008 [US2] Apply with `sudo nixos-rebuild switch --flake .#laptop`, then manually
  verify: Obsidian launches, a vault can be created/opened, a note can be created and
  saved, and the note file exists on disk after closing and reopening Obsidian
  (quickstart.md step 4) (depends on T007) — NOT DONE: requires the user to run `switch`
  and manually verify GUI behavior

**Checkpoint**: Chrome and Obsidian are both fully functional and independently verified.

---

## Phase 5: User Story 3 - Manage passwords with Bitwarden (Priority: P3)

**Goal**: `dmiller` can launch the Bitwarden desktop app from the desktop environment
immediately after a rebuild and log in to an existing vault.

**Independent Test**: On a rebuilt system, launch the Bitwarden desktop app, log in to an
existing Bitwarden account, and confirm vault items are visible (spec.md User Story 3
Acceptance Scenarios).

### Implementation for User Story 3

- [X] T009 [US3] Add `pkgs.bitwarden-desktop` to `environment.systemPackages` in
  `modules/nixos/desktop-apps.nix` (depends on T001/T002; edits the same file as T003/T006,
  so do this after T006 is committed to avoid a merge conflict)
- [X] T010 [US3] Run `nix flake check` and
  `nixos-rebuild dry-activate --flake .#laptop`; confirm `bitwarden-desktop` appears in
  the activation diff (quickstart.md step 1) (depends on T009) — verified via combined
  `nixos-rebuild dry-build` (see T012); exit 0
- [ ] T011 [US3] Apply with `sudo nixos-rebuild switch --flake .#laptop`, then manually
  verify: the Bitwarden desktop app launches, presents a login screen, and shows vault
  items after logging in with an existing account (quickstart.md step 5) (depends on T010)
  — NOT DONE: requires the user to run `switch` and manually verify GUI behavior

**Checkpoint**: All three applications (Chrome, Obsidian, Bitwarden) are fully functional
and independently verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final, whole-feature validation once all three applications are in place.

- [X] T012 Run `nix flake check` and `nixos-rebuild dry-activate --flake .#laptop` once
  more with all three packages present together, confirming a clean combined evaluation
  and build (Constitution Principle IV) (depends on T003, T006, T009) — ran
  `nix flake check` (all checks passed) and `nixos-rebuild dry-build` (exit 0; 191.8 MiB
  to fetch for the three new apps and deps, no errors)
- [ ] T013 Reboot (or re-run `nixos-rebuild switch --flake .#laptop` with no further
  changes) and confirm each application's prior state (Chrome bookmark, Obsidian note,
  Bitwarden logged-in session) is still present, per spec.md Success Criteria
  SC-001–SC-003 and quickstart.md step 6 (depends on T005, T008, T011) — NOT DONE: blocked
  on T005/T008/T011

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately. BLOCKS all user
  stories (T001 → T002).
- **User Story 1 (Phase 3)**: Depends on Phase 2. No dependency on US2/US3.
- **User Story 2 (Phase 4)**: Depends on Phase 2. Logically independent of US1, but its
  implementation task (T006) touches the same file as T003 — sequence after T003 to avoid
  a trivial merge conflict, not because of a functional dependency.
- **User Story 3 (Phase 5)**: Depends on Phase 2. Logically independent of US1/US2, but
  its implementation task (T009) touches the same file as T003/T006 — sequence after T006
  for the same reason.
- **Polish (Phase 6)**: Depends on all three user stories being complete.

### Within Each User Story

- Add package → validate build (`flake check` + `dry-activate`) → apply and manually
  verify. Each story is a complete, independently testable increment before moving to the
  next.

### Parallel Opportunities

- T001 and T002 are not parallel (T002 imports the file T001 creates).
- T003, T006, and T009 (adding each package) all edit
  `modules/nixos/desktop-apps.nix` and so are **not** marked `[P]` even though the
  underlying user stories are logically independent — do them in sequence (US1 → US2 →
  US3) to avoid edit conflicts on the same file.
- Once a story's package line is added, its own validate/verify tasks (e.g., T004→T005)
  are sequential (build before manual verification) but independent of the other stories'
  verification work — e.g., T005 (verifying Chrome) has no dependency on T007/T008.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 2: Foundational (T001–T002).
2. Complete Phase 3: User Story 1 — Chrome (T003–T005).
3. **STOP and VALIDATE**: Chrome installs, launches, and persists state; Firefox
   unaffected.
4. This alone is a shippable increment (per spec.md, Chrome is the highest-priority app).

### Incremental Delivery

1. Foundational (T001–T002) → module ready.
2. Add Chrome (T003–T005) → validate → done (MVP).
3. Add Obsidian (T006–T008) → validate → done.
4. Add Bitwarden (T009–T011) → validate → done.
5. Final combined check and persistence validation (T012–T013).

---

## Notes

- No `[P]` markers are used for the three package-addition tasks (T003, T006, T009)
  despite each belonging to an independent user story, because all three edit the same
  file (`modules/nixos/desktop-apps.nix`) — see Parallel Opportunities above.
- Commit after each user story's checkpoint (T005, T008, T011) so each priority level is
  independently deployable/revertible.
- Stop at any checkpoint to ship or demo that story's app on its own.
