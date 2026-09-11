# Implementation Plan: Harden SSH Access

**Branch**: `002-harden-ssh-access` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-harden-ssh-access/spec.md`

## Summary

Close the SSH password-authentication gap tracked since feature 001 (spec FR-008, now a
violation of Constitution Principle VI) by: (1) declaring the existing, already-working
authorized public key for `dmiller` in `modules/nixos/users.nix` instead of leaving it as an
unmanaged file on disk, (2) confirming key-based login still works with that change alone
(password auth still on), and only then (3) flipping
`services.openssh.settings.PasswordAuthentication` to `false` and disabling SSH root login
outright in `modules/nixos/remote-dev.nix`. The two-step order exists specifically so the
fallback (password auth) is never removed before the replacement (key auth) is proven
working on this exact machine.

## Technical Context

**Language/Version**: Nix expression language, same flake as feature 001 (`hosts/laptop`
via `flake.nix`, nixpkgs pinned in `flake.lock`).

**Primary Dependencies**: None new — reuses the existing `nixpkgs` input and the
`modules/nixos/{users,remote-dev}.nix` modules created in feature 001.

**Storage**: N/A.

**Testing**: `nix flake check` + a dry build, plus a live SSH login check with the existing
key (FR-004) performed *before* password authentication is disabled — this is the actual
safety gate for this feature, not just a formality.

**Target Platform**: Same laptop host as feature 001 (`x86_64-linux`).

**Project Type**: Same single Nix flake system-configuration repository.

**Performance Goals**: N/A.

**Constraints**: MUST NOT lock out remote SSH access (FR-004); MUST NOT alter local
console/graphical login (FR-005); the public key being declared is not a secret (Secrets
Management section) so no secrets-handling mechanism is needed for this feature.

**Scale/Scope**: One host (laptop), one user account (`dmiller`), one authorized key. No
new users, hosts, or SSH-adjacent services in scope (spec Assumptions).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle / Section | Check | Result |
|---|---|---|
| I. Declarative Configuration Only | FR-002 moves the authorized key from an unmanaged `~/.ssh/authorized_keys` file into `modules/nixos/users.nix`. | PASS |
| II. Reproducibility & Pinned Inputs | No new inputs; no change to `flake.lock`. | PASS |
| III. Host Modularity & Composability | Reuses existing `modules/nixos/{users,remote-dev}.nix`; no laptop-specific content added to either. | PASS |
| IV. Build & Validate Before Merge (NON-NEGOTIABLE) | FR-004 requires confirming key-based login works *before* the password-auth fallback is removed — a stronger-than-usual instance of this gate. | PASS |
| V. Simplicity & Incremental Change | Scope is exactly the flagged issue (password auth) per spec Assumptions; no fail2ban/port-change/VPN scope creep. | PASS |
| VI. Secure by Default (NON-NEGOTIABLE) | This feature exists specifically to satisfy this principle — it remediates the tracked violation the principle's own adoption flagged. | PASS |
| Secrets Management | The authorized key is a public key, explicitly not a secret per that section; nothing here requires `sops-nix`/`agenix`. | PASS |
| Development Workflow | This security-relevant change is going through the full Spec Kit workflow, as Governance expects for non-trivial changes. | PASS |

No violations — Complexity Tracking is not needed.

## Project Structure

### Documentation (this feature)

```text
specs/002-harden-ssh-access/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

No `contracts/` directory, for the same reason as feature 001: this repo has no external
API/interface for other systems to consume.

### Source Code (repository root)

```text
modules/
└── nixos/
    ├── users.nix        # MODIFIED: add users.users.dmiller.openssh.authorizedKeys.keys
    └── remote-dev.nix   # MODIFIED: PasswordAuthentication -> false, add PermitRootLogin = "no"
```

No new files. Both modules already exist from feature 001 and already own exactly the
settings this feature touches (per feature 001's `data-model.md` Concern Module mapping:
`users.nix` owns `users.users.dmiller.*`; `remote-dev.nix` owns `services.openssh.*`).

**Structure Decision**: Extend the two existing concern modules rather than creating a new
one — the settings this feature changes are already owned by `users.nix` and
`remote-dev.nix` respectively (see research.md Decision 1), consistent with Constitution
Principle III (no duplicated/competing ownership of a setting).

## Complexity Tracking

*No Constitution Check violations — this section is intentionally empty.*
