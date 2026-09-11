# Phase 0 Research: Harden SSH Access

## Decision 1: Extend existing modules rather than create a new one

- **Decision**: Add `users.users.dmiller.openssh.authorizedKeys.keys` to the existing
  `modules/nixos/users.nix`; change `services.openssh.settings.PasswordAuthentication` and
  add `services.openssh.settings.PermitRootLogin` in the existing
  `modules/nixos/remote-dev.nix`. No new module file.
- **Rationale**: Feature 001's `data-model.md` already assigns `users.users.dmiller.*` to
  `users.nix` and `services.openssh.*` to `remote-dev.nix`. Every setting this feature
  touches falls under one of those two existing owners, so adding a third module would
  duplicate ownership boundaries for no benefit (Constitution Principle III/V).
- **Alternatives considered**: A new `modules/nixos/ssh-hardening.nix` — rejected: would
  split `services.openssh.*` across two files (`remote-dev.nix` and the new one), which is
  exactly the kind of duplicated ownership feature 001's User Story 2 was meant to prevent.

## Decision 2: Two-step rollout order (key first, password-disable second)

- **Decision**: Implement and validate in two ordered steps: (a) declare the authorized key
  in `users.nix`, build, activate, and confirm key-based login works — with
  `PasswordAuthentication` still `true` — before (b) flipping
  `PasswordAuthentication` to `false` and `PermitRootLogin` to `"no"` in `remote-dev.nix`,
  then re-validating.
- **Rationale**: FR-004 explicitly requires proving the replacement (key auth) works before
  removing the fallback (password auth) on this exact machine. Doing both in one shot would
  mean the first time key-only auth is actually exercised is also the moment password auth
  is gone — if anything about the declared key were wrong, there would be no fallback left to
  recover remote access with (only physical access to the laptop, which is a legitimate but
  much less convenient recovery path).
- **Alternatives considered**: *Single combined change* — rejected: removes the safety
  margin FR-004 exists to provide, for no benefit (both steps land in the same feature
  either way; ordering costs nothing extra).

## Decision 3: Public key value(s)

- **Correction during planning**: this decision originally assumed `~/.ssh/authorized_keys`
  already contained `~/.ssh/id_ed25519.pub`. Checking the actual file content showed it
  instead contains a *different* key (`ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINiQi43ehLNCXZN+Uxxn+Rt6PnXOy5iHiy/osYe6rjpn micro@krux-desktop`)
  — the one actually proven to grant remote access today. `id_ed25519.pub`
  (`dmiller@nixos`) exists on this laptop but had no proven remote-login use.
- **Decision**: Declare **both** keys in `users.users.dmiller.openssh.authorizedKeys.keys`:
  the `krux-desktop` key (proven working) and `id_ed25519.pub` (this laptop's own key).
  User decision, made explicitly after this discrepancy was surfaced.
- **Rationale**: Declaring only `id_ed25519.pub` risked NixOS's activation-managed
  `authorized_keys` dropping the key that currently works, while declaring only the
  `krux-desktop` key would forgo giving the laptop itself a usable key for its own account.
  Declaring both preserves every currently-possible access path — this is a public key,
  so committing either carries no secrecy concern (Secrets Management section explicitly
  excludes public keys).
- **Alternatives considered**:
  - *Only `id_ed25519.pub`* (the original, incorrect assumption) — rejected: would have
    risked losing the one key proven to work.
  - *Only the `krux-desktop` key* — rejected by explicit user choice; keeping
    `id_ed25519.pub` too costs nothing and avoids relying on a single external client.
  - *Generating a new dedicated key* — rejected: unnecessary churn given two working keys
    already exist.

## Decision 4: `PermitRootLogin`

- **Decision**: Explicitly set `services.openssh.settings.PermitRootLogin = "no";` in
  `remote-dev.nix`.
- **Rationale**: FR-003 requires root SSH login be disabled outright. Modern NixOS/OpenSSH
  defaults to `"prohibit-password"` (root can still log in with a key) rather than fully
  `"no"`, so this must be set explicitly to meet FR-003's "no operational need for remote
  root login" requirement on a single-user machine.
- **Alternatives considered**: Leaving the default (`"prohibit-password"`) — rejected: does
  not satisfy FR-003, which calls for root SSH login to be unreachable, not merely
  password-protected.

**Output**: All technical unknowns resolved; no `NEEDS CLARIFICATION` markers remain.
