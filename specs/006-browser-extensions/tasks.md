---

description: "Task list for Browser Extensions (Chrome & Firefox)"
---

# Tasks: Browser Extensions (Chrome & Firefox)

**Input**: Design documents from `/specs/006-browser-extensions/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: No test framework applies to declarative policy configuration (see `plan.md`
Technical Context → Testing). Validation follows Constitution Principle IV
(`nix flake check` + dry-build) plus the manual per-browser checks in `quickstart.md`,
represented as explicit tasks below.

**Organization**: Tasks are grouped by user story (content blocker = US1, Bitwarden =
US2, Dark Reader = US3, Vimium/Vimium-FF = US4).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

Single NixOS flake configuration repo (see `plan.md` Project Structure):

- `modules/nixos/browser-extensions.nix` — new module holding both browsers' policy
- `hosts/laptop/configuration.nix` — host config that imports the new module

Concrete extension identifiers referenced below are documented in `research.md`.

---

## Phase 1: Setup

*No project initialization is needed — this feature edits an existing, already-building
NixOS flake configuration. Setup work is folded into Phase 2 below, since the one new
file this feature needs (`browser-extensions.nix`) is itself a blocking prerequisite for
every user story.*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create the shared module — both policy blocks, empty — and wire it into the
host config that every user story's extension entry depends on.

**⚠️ CRITICAL**: No user story task can begin until this phase is complete — all four add
entries to the same two option blocks in the same file created here.

- [X] T001 Create `modules/nixos/browser-extensions.nix` with
  `programs.chromium = { enable = true; extensions = [ ]; };` and
  `programs.firefox.policies.ExtensionSettings = { };` skeletons
- [X] T002 Import `../../modules/nixos/browser-extensions.nix` in the `imports` list of
  `hosts/laptop/configuration.nix` (depends on T001)

**Checkpoint**: `nix flake check` succeeds with the new (empty) module wired in —
foundation ready, user story implementation can now begin.

---

## Phase 3: User Story 1 - Browse with ads and trackers blocked (Priority: P1) 🎯 MVP

**Goal**: uBlock Origin Lite is force-installed and enabled in Chrome; the full uBlock
Origin is force-installed and enabled in Firefox.

**Independent Test**: On a rebuilt system, open Chrome and Firefox, confirm the
respective extension is present/enabled, and confirm ads/trackers are blocked on a test
page (spec.md User Story 1 Acceptance Scenarios).

### Implementation for User Story 1

- [X] T003 [US1] In `modules/nixos/browser-extensions.nix`, add
  `"ddkjiahejlhfcafbddmgiahcphecmpfh"` (uBlock Origin Lite) to
  `programs.chromium.extensions` (depends on T001/T002)
- [X] T004 [US1] In `modules/nixos/browser-extensions.nix`, add the
  `"uBlock0@raymondhill.net"` entry (`install_url =
  "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
  installation_mode = "force_installed";`) to
  `programs.firefox.policies.ExtensionSettings` (depends on T001/T002; same file as
  T003, do after it)
- [X] T005 [US1] Run `nix flake check` and `nixos-rebuild dry-build --flake .#laptop`;
  confirm both entries appear in the built policy JSON (quickstart.md step 1) (depends
  on T003, T004) — verified via combined check (see T019); both JSON files inspected
  directly and contain correct entries
- [ ] T006 [US1] Apply with `sudo nixos-rebuild switch --flake .#laptop`, then manually
  verify per quickstart.md step 3: uBlock Origin Lite is installed/enabled in Chrome,
  uBlock Origin is installed/enabled in Firefox, and both block a known ad/tracker test
  page (depends on T005) — NOT DONE: requires the user to run `switch` and manually
  verify GUI behavior

**Checkpoint**: Content blocking is fully functional and independently verified in both
browsers.

---

## Phase 4: User Story 2 - Access passwords via the Bitwarden extension (Priority: P2)

**Goal**: The Bitwarden extension is force-installed and enabled in both Chrome and
Firefox.

**Independent Test**: On a rebuilt system, open the Bitwarden extension in each browser
and confirm it opens and prompts for (or already has) login (spec.md User Story 2
Acceptance Scenarios).

### Implementation for User Story 2

- [X] T007 [US2] In `modules/nixos/browser-extensions.nix`, add
  `"nngceckbapebfimnlniiiahkandclblb"` (Bitwarden) to `programs.chromium.extensions`
  (depends on T001/T002; same file as T003, do after it)
- [X] T008 [US2] In `modules/nixos/browser-extensions.nix`, add the
  `"{446900e4-71c2-419f-a6a7-df9c091e268b}"` entry (`install_url =
  "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
  installation_mode = "force_installed";`) to
  `programs.firefox.policies.ExtensionSettings` (depends on T001/T002; do after T004)
- [X] T009 [US2] Run `nix flake check` and `nixos-rebuild dry-build --flake .#laptop`;
  confirm both entries appear in the built policy JSON (quickstart.md step 1) (depends
  on T007, T008) — verified via combined check (see T019)
- [ ] T010 [US2] Apply with `sudo nixos-rebuild switch --flake .#laptop`, then manually
  verify per quickstart.md step 4: the Bitwarden extension is installed/enabled in both
  browsers, opens, and can autofill a saved login (depends on T009) — NOT DONE: requires
  the user to run `switch` and manually verify GUI behavior

**Checkpoint**: Content blocking and Bitwarden are both fully functional and
independently verified.

---

## Phase 5: User Story 3 - Browse comfortably at night with Dark Reader (Priority: P3)

**Goal**: Dark Reader is force-installed and enabled in both Chrome and Firefox.

**Independent Test**: On a rebuilt system, visit a light-themed site in each browser and
confirm Dark Reader is installed/enabled and renders it in dark mode (spec.md User Story
3 Acceptance Scenarios).

### Implementation for User Story 3

- [X] T011 [US3] In `modules/nixos/browser-extensions.nix`, add
  `"eimadpbcbfnmbkopoojfekhnkhdbieeh"` (Dark Reader) to `programs.chromium.extensions`
  (depends on T001/T002; same file as T007, do after it)
- [X] T012 [US3] In `modules/nixos/browser-extensions.nix`, add the
  `"addon@darkreader.org"` entry (`install_url =
  "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
  installation_mode = "force_installed";`) to
  `programs.firefox.policies.ExtensionSettings` (depends on T001/T002; do after T008)
- [X] T013 [US3] Run `nix flake check` and `nixos-rebuild dry-build --flake .#laptop`;
  confirm both entries appear in the built policy JSON (quickstart.md step 1) (depends
  on T011, T012) — verified via combined check (see T019)
- [ ] T014 [US3] Apply with `sudo nixos-rebuild switch --flake .#laptop`, then manually
  verify per quickstart.md step 5: Dark Reader is installed/enabled in both browsers and
  renders a light-themed test site in dark mode (depends on T013) — NOT DONE: requires
  the user to run `switch` and manually verify GUI behavior

**Checkpoint**: Content blocking, Bitwarden, and Dark Reader are all fully functional and
independently verified.

---

## Phase 6: User Story 4 - Navigate pages by keyboard with Vimium (Priority: P4)

**Goal**: Vimium is force-installed and enabled in Chrome; Vimium-FF is force-installed
and enabled in Firefox.

**Independent Test**: On a rebuilt system, trigger a keyboard-navigation shortcut (e.g.,
link hints) on a normal page in each browser and confirm it responds (spec.md User Story
4 Acceptance Scenarios).

### Implementation for User Story 4

- [X] T015 [US4] In `modules/nixos/browser-extensions.nix`, add
  `"dbepggeogbaibhgnhhndojpepiihcmeb"` (Vimium) to `programs.chromium.extensions`
  (depends on T001/T002; same file as T011, do after it)
- [X] T016 [US4] In `modules/nixos/browser-extensions.nix`, add the
  `"{d7742d87-e61d-4b78-b8a1-b469842139fa}"` entry (`install_url =
  "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
  installation_mode = "force_installed";`) to
  `programs.firefox.policies.ExtensionSettings` (depends on T001/T002; do after T012)
- [X] T017 [US4] Run `nix flake check` and `nixos-rebuild dry-build --flake .#laptop`;
  confirm both entries appear in the built policy JSON (quickstart.md step 1) (depends
  on T015, T016) — verified via combined check (see T019)
- [ ] T018 [US4] Apply with `sudo nixos-rebuild switch --flake .#laptop`, then manually
  verify per quickstart.md step 6: Vimium responds to a keyboard shortcut in Chrome and
  Vimium-FF responds in Firefox (depends on T017) — NOT DONE: requires the user to run
  `switch` and manually verify GUI behavior

**Checkpoint**: All four extension families are fully functional and independently
verified in both browsers.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final, whole-feature validation once all four extension families are in
place.

- [X] T019 Run `nix flake check` and `nixos-rebuild dry-build --flake .#laptop` once
  more with all four families present together in both policy blocks, confirming a
  clean combined evaluation and build (Constitution Principle IV) (depends on T003,
  T004, T007, T008, T011, T012, T015, T016) — `flake check`: all checks passed;
  `nixos-rebuild dry-build`: exit 0; both `/etc/opt/chrome/policies/managed/default.json`
  and `/etc/firefox/policies/policies.json` builds inspected directly and contain all 4
  entries each, correctly formed
- [ ] T020 Manually disable one extension in one browser, re-run
  `sudo nixos-rebuild switch --flake .#laptop` with no further config changes, relaunch
  the browser, and confirm the extension is re-enabled — per spec.md Edge Cases and
  quickstart.md step 7 (depends on T006, T010, T014, T018) — NOT DONE: blocked on
  T006/T010/T014/T018

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately. BLOCKS all user
  stories (T001 → T002).
- **User Story 1 (Phase 3)**: Depends on Phase 2. No dependency on US2/US3/US4.
- **User Story 2 (Phase 4)**: Depends on Phase 2. Logically independent of US1/US3/US4,
  but its implementation tasks (T007, T008) touch the same file/option blocks as
  US1's (T003, T004) — sequence after US1 to avoid a trivial merge conflict, not because
  of a functional dependency.
- **User Story 3 (Phase 5)**: Depends on Phase 2. Same file-ordering note — sequence
  after US2.
- **User Story 4 (Phase 6)**: Depends on Phase 2. Same file-ordering note — sequence
  after US3.
- **Polish (Phase 7)**: Depends on all four user stories being complete.

### Within Each User Story

- Add Chrome ID → add Firefox policy entry → validate build (`flake check` +
  `dry-build`) → apply and manually verify. Each story is a complete, independently
  testable increment before moving to the next.

### Parallel Opportunities

- T001 and T002 are not parallel (T002 imports the file T001 creates).
- Within each story, the Chrome-list task and the Firefox-policy task
  (e.g., T003/T004) edit the *same file* (though different option blocks) and are kept
  sequential for clarity rather than marked `[P]`.
- Across stories, all eight "add an entry" tasks (T003, T004, T007, T008, T011, T012,
  T015, T016) touch the same file and so are **not** marked `[P]` even though the
  underlying user stories are logically independent — do them in priority order (US1 →
  US2 → US3 → US4).
- Once a story's entries are added, its own validate/verify tasks are sequential (build
  before manual verification) but independent of other stories' verification work.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 2: Foundational (T001–T002).
2. Complete Phase 3: User Story 1 — content blocker (T003–T006).
3. **STOP and VALIDATE**: uBlock Origin Lite (Chrome) and uBlock Origin (Firefox) both
   install, enable, and block ads/trackers.
4. This alone is a shippable increment (per spec.md, content blocking is the
   highest-priority extension family).

### Incremental Delivery

1. Foundational (T001–T002) → module ready.
2. Add content blocker (T003–T006) → validate → done (MVP).
3. Add Bitwarden (T007–T010) → validate → done.
4. Add Dark Reader (T011–T014) → validate → done.
5. Add Vimium/Vimium-FF (T015–T018) → validate → done.
6. Final combined check and re-declaration validation (T019–T020).

---

## Notes

- No `[P]` markers are used for the eight "add an extension entry" tasks despite each
  belonging to an independent user story, because all eight edit the same file
  (`modules/nixos/browser-extensions.nix`) — see Parallel Opportunities above.
- Commit after each user story's checkpoint (T006, T010, T014, T018) so each priority
  level is independently deployable/revertible.
- Stop at any checkpoint to ship or demo that story's extension family on its own.
