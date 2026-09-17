---

description: "Task list for Harden SSH Access"
---

# Tasks: Harden SSH Access

**Input**: Design documents from `/specs/002-harden-ssh-access/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: No automated test suite — validation is `nix flake check` / `nixos-rebuild` plus
live SSH login checks, called out explicitly below per FR-004 and Constitution Principle IV.

**Organization**: Tasks are grouped by user story from spec.md (US1 = P1, US2 = P2). Note:
this feature has an unusually strict *sequencing* requirement (research.md Decision 2) —
password authentication must never be disabled before key-based login is proven working on
this machine. That safety gate is modeled as the Foundational phase, which both stories
depend on.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)
- File paths are relative to the repository root unless otherwise noted

## Phase 1: Setup

**Purpose**: Confirm the baseline before touching anything.

- [X] T001 Confirm the current baseline: compare `~/.ssh/id_ed25519.pub` against
  `~/.ssh/authorized_keys` and `nix flake check` on the unmodified repo — no files changed.
  **Result**: they do NOT match — `authorized_keys` holds a different key
  (`micro@krux-desktop`), not `id_ed25519.pub` (`dmiller@nixos`) as originally assumed. User
  decided to declare both (research.md Decision 3, corrected); `nix flake check` passed
  clean (research.md Decision 3)

**Checkpoint**: Baseline confirmed; safe to begin.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Declare the authorized key in Nix and prove key-based login works — this MUST
succeed, with password authentication still enabled as a fallback, before User Story 1's
phase may begin (FR-004).

**⚠️ CRITICAL**: Do not proceed to Phase 3 until T004 below passes.

- [X] T002 Add
  `users.users.dmiller.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINiQi43ehLNCXZN+Uxxn+Rt6PnXOy5iHiy/osYe6rjpn micro@krux-desktop" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPa4vo9/0MdRuvVakFKou5gsLRvaxsR/aerEvulZBT+S dmiller@nixos" ];`
  to `modules/nixos/users.nix` (FR-002, research.md Decision 3 — both keys, per corrected
  finding and user decision) (depends on T001)
- [ ] T003 Run `nix flake check`, then
  `sudo nixos-rebuild dry-activate --flake .#laptop`, then
  `sudo nixos-rebuild switch --flake .#laptop` to apply — `PasswordAuthentication` is still
  `true` at this point (quickstart.md Step 1) (depends on T002)
- [ ] T004 From a separate session/device, confirm SSH login with the key succeeds with no
  password prompt (quickstart.md Step 2); **do not proceed until this passes** (FR-004)
  (depends on T003)

**Checkpoint**: Key-based login is proven working. It is now safe to remove the password
fallback.

---

## Phase 3: User Story 1 - SSH access requires a key, not a password (Priority: P1) 🎯 MVP

**Goal**: Password-based SSH authentication is disabled; only key-based login works. Root
SSH login is disabled outright.

**Independent Test**: A client with the authorized key logs in with no password prompt; a
client without the key and attempting a password is rejected (spec.md Acceptance Scenarios
1–2).

### Implementation for User Story 1

- [ ] T005 [US1] In `modules/nixos/remote-dev.nix`, set
  `services.openssh.settings.PasswordAuthentication = false;` and add
  `services.openssh.settings.PermitRootLogin = "no";` (FR-001, FR-003, research.md
  Decision 4) (depends on T004)
- [ ] T006 [US1] Run `nix flake check`, then
  `sudo nixos-rebuild dry-activate --flake .#laptop`, then
  `sudo nixos-rebuild switch --flake .#laptop` (depends on T005)
- [ ] T007 [US1] Confirm key-based login still succeeds after the change (SC-002; quickstart.md
  Step 4) (depends on T006)
- [ ] T008 [US1] Confirm a password-only login attempt (no key offered) is rejected (SC-001)
  and that `root` login is rejected regardless of method (FR-003) (quickstart.md Step 4)
  (depends on T006)

**Checkpoint**: User Story 1 fully delivered — password authentication is gone, only
key-based access works, root login is disabled.

---

## Phase 4: User Story 2 - Authorized keys are declared in the repo (Priority: P2)

**Goal**: The authorized key is reproducible from the repo alone, not dependent on the
machine's own unmanaged `~/.ssh/authorized_keys` file.

**Independent Test**: Inspecting `modules/nixos/users.nix` (not the live filesystem) shows
the authorized key; the live `~/.ssh/authorized_keys` is shown to be *derived from* that
declaration, not the other way around (spec.md Acceptance Scenario 1).

### Implementation for User Story 2

> Most of this story's actual work already happened in Phase 2 (T002), since the key had to
> be declared there to satisfy FR-004's ordering requirement. This phase verifies the
> property User Story 2 cares about, rather than re-doing the declaration.

- [ ] T009 [US2] Confirm `modules/nixos/users.nix` is the sole source of the authorized key
  (`grep -A2 authorizedKeys modules/nixos/users.nix`) (SC-003; quickstart.md Step 6)
  (depends on T002)
- [ ] T010 [US2] Confirm the live `~/.ssh/authorized_keys` content matches what NixOS's
  activation derived from `users.nix` (i.e., it's now machine-generated output of the
  declared config, not independently hand-maintained state) (depends on T003)

**Checkpoint**: Both user stories independently verified.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [ ] T011 Log out and back in at the laptop's own screen (KDE/SDDM) as `dmiller` to confirm
  local console/graphical login is completely unaffected (SC-004; quickstart.md Step 5)
  (depends on T006)
- [ ] T012 Run `sudo sshd -T | grep -Ei 'passwordauthentication|permitrootlogin'` to confirm
  the *effective* running sshd configuration matches the declared settings exactly, as a
  final cross-check beyond the Nix source (depends on T006)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS User Story 1. T004 is a hard gate:
  do not begin Phase 3 until it passes.
- **User Story 1 (Phase 3)**: Depends on Foundational (specifically T004 passing).
- **User Story 2 (Phase 4)**: Depends on Foundational (T002/T003); does not depend on User
  Story 1 — its verification tasks can run any time after Phase 2 completes, including in
  parallel with Phase 3.
- **Polish (Phase 5)**: Depends on User Story 1 (T006) being applied.

### Parallel Opportunities

This feature is intentionally sequential — its entire point is a safety-ordered rollout, not
parallel throughput. The one real opportunity: once Phase 2 completes, **Phase 4 (User Story
2's verification, T009–T010) can run in parallel with Phase 3 (User Story 1)**, since US2
only inspects state Phase 2 already produced.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational — **do not proceed past T004 until it passes**
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: run quickstart.md Step 4 in full
5. At this point the actual security fix (no password SSH auth) is live

### Incremental Delivery

1. Setup + Foundational → key-based login proven working, password auth still on as a
   fallback
2. User Story 1 → password auth disabled, root login disabled (the fix)
3. User Story 2 → verified that this is reproducible from the repo, not machine-local state
4. Polish → local login confirmed unaffected, effective sshd config cross-checked

---

## Notes

- [P] is not used in this feature — every task in the critical path depends on the previous
  one by design (research.md Decision 2); the only non-sequential relationship is Phase 3 vs
  Phase 4, noted above.
- [Story] labels map tasks to spec.md's user stories for traceability.
- T004 is the single most important checkpoint in this feature: it is the entire reason
  Constitution Principle IV and FR-004 exist here — do not skip or shortcut it.
