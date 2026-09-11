# Feature Specification: Harden SSH Access

**Feature Branch**: `002-harden-ssh-access`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: (none typed) — continuing the next action agreed at the end of
the constitution amendment adding Principle VI (Secure by Default): SSH password
authentication is a tracked violation of that principle and must be remediated, closing the
deferral recorded as FR-008 in `specs/001-initial-environment-setup/spec.md`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - SSH access requires a key, not a password (Priority: P1)

As the owner of this laptop, I want remote SSH login to require a private key I hold rather
than a password, so that a guessed, leaked, or brute-forced password can no longer be used
to remotely access my machine.

**Why this priority**: This is the actual security fix the feature exists to deliver, and
the specific violation of Constitution Principle VI that prompted this feature.

**Independent Test**: From a client holding the authorized private key, SSH login succeeds
with no password prompt. From any client attempting password authentication (no valid key
offered), the SSH server refuses the connection rather than prompting for or accepting a
password.

**Acceptance Scenarios**:

1. **Given** the laptop's configuration is built and active, **When** a client connects over
   SSH offering the authorized private key, **Then** login succeeds without a password
   prompt.
2. **Given** the laptop's configuration is built and active, **When** a client connects over
   SSH without a valid key and attempts a password, **Then** the connection is rejected.

---

### User Story 2 - Authorized keys are declared in the repo, not left as unmanaged state (Priority: P2)

As the maintainer of this repo, I want the SSH public key(s) allowed to log in as `dmiller`
declared in this repository's Nix configuration, so that rebuilding the machine from the
repo reproduces working SSH access with no manual, out-of-repo step.

**Why this priority**: Directly follows from Constitution Principle I (Declarative
Configuration Only) — today's working key is only present in `~/.ssh/authorized_keys`,
which this repo doesn't manage. Lower priority than User Story 1 because SSH is already
functionally key-capable today; this story makes that fact durable across a rebuild rather
than fixing a live security gap.

**Independent Test**: Starting from a configuration build that does not yet have the key in
`~/.ssh/authorized_keys`, applying the repo's configuration alone (no manual file edit)
results in the same key being authorized.

**Acceptance Scenarios**:

1. **Given** a fresh build of the laptop's configuration, **When** the configuration is
   activated, **Then** the authorized public key(s) for `dmiller` come from the repo, not
   from a manually maintained `~/.ssh/authorized_keys` file.

---

### Edge Cases

- What happens if the declared public key is wrong, mistyped, or missing when this change is
  activated? Remote SSH access would be lost — mitigated by validating login with the
  existing key succeeds *before* password authentication is disabled (see Functional
  Requirements), and by physical access to the laptop remaining available regardless (this
  is not a headless/remote-only machine).
- Does this affect logging in locally at the laptop's own keyboard/screen (the KDE/SDDM
  session)? No — this feature is scoped to the SSH daemon only; local console/graphical
  login is a separate authentication path and is unaffected.
- What about `root` logging in over SSH? Already effectively unreachable day-to-day since
  there's no `root` password workflow in use; this feature makes that explicit and
  unconditional rather than relying on an implicit default.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: SSH access to the laptop MUST require key-based authentication;
  password-based SSH authentication MUST be disabled. This supersedes and closes FR-008 from
  `specs/001-initial-environment-setup/spec.md`, which had deferred this exact change.
- **FR-002**: The public key(s) authorized to log in as `dmiller` over SSH MUST be declared
  in this repository's Nix configuration, not left as an unmanaged file on the running
  machine.
- **FR-003**: SSH login as `root` MUST be disabled outright (not merely "password
  disabled") — this is a single-user machine with no operational need for remote root
  login.
- **FR-004**: Before password authentication is disabled, key-based login with the existing
  authorized key MUST be confirmed working, so the change cannot silently lock out remote
  access (Constitution Principle IV: build & validate before merge, applied here as
  "validate access before removing the fallback").
- **FR-005**: This feature MUST NOT change local/physical console or graphical
  (KDE/SDDM) login in any way — scope is limited to the SSH daemon's authentication method.

### Key Entities

- **Authorized SSH Key**: A public key permitted to authenticate as a specific user account
  over SSH; owned by that user account, declared in configuration rather than left as loose
  file state on the machine.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of SSH login attempts using only a password (no valid key) are rejected
  after this change.
- **SC-002**: SSH login using the existing authorized private key succeeds on the first
  attempt after the change, with zero manual steps beyond normal `ssh` usage.
- **SC-003**: Rebuilding the machine from a clean checkout of this repository reproduces the
  same authorized SSH key(s) with no manual edit to any file outside the repo.
- **SC-004**: 100% of local console/graphical login paths continue to work exactly as before
  this change.

## Assumptions

- **Correction found during planning**: the original assumption here was that
  `~/.ssh/authorized_keys` already contained the `id_ed25519.pub` key present on this
  laptop. Checking the actual file content showed that's wrong — `authorized_keys` instead
  contains a different key, labeled `micro@krux-desktop`, meaning a separate client is the
  one actually proven to have remote access today. Declaring only `id_ed25519.pub` would
  have risked NixOS's activation-managed `authorized_keys` dropping the `krux-desktop` key
  that currently works, while adding one with no proven remote-login use.
- Per explicit user decision, **both** keys are declared in FR-002: the existing
  `krux-desktop` key (proven to currently grant access) and this laptop's own
  `id_ed25519.pub` (`dmiller@nixos`, present locally but not previously proven for remote
  login). Neither access path is lost, and no new key material needs to be generated or
  distributed.
- Only the single `dmiller` account is in scope; this machine has no other user accounts
  needing SSH access today.
- Broader SSH/network hardening (fail2ban-style rate limiting, changing the listening port,
  VPN-only access, etc.) is out of scope for this feature — Constitution Principle V
  (Simplicity & Incremental Change) favors making the one specific fix that was actually
  flagged (password authentication) rather than bundling in unrelated hardening. Additional
  hardening can be proposed as its own future feature if a real need arises.
- This feature builds on the existing `modules/nixos/remote-dev.nix` module from feature 001
  rather than introducing a new module, since it modifies settings that module already owns.
