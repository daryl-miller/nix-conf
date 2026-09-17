# Feature Specification: Initial Minimum Environment Setup

**Feature Branch**: `001-initial-environment-setup`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "initial minimum environment setup. This means consolidating the existing hardware configuration, fixing any issues contained within and bringing across the original nix.conf and structuring the contents based on type e.g. locale."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Rebuild the laptop from the repo alone (Priority: P1)

As the owner of this laptop, I want the repository to be a complete, correct, declarative
description of my running system, so that I can rebuild or restore this machine from the
repo without depending on the machine's own `/etc/nixos` files as the source of truth.

**Why this priority**: This is the entire reason the repo exists. Until the repo can produce
a working system on its own, everything else (structure, later hosts, secrets, etc.) is
built on an untrustworthy foundation.

**Independent Test**: Run a dry build/check of the laptop's NixOS configuration from the
repo (e.g., `nixos-rebuild dry-activate --flake .#<host>` or `nix flake check`) and confirm
it succeeds and reflects the machine's actual current settings (bootloader, hostname,
networking, locale, desktop environment, users, audio, printing).

**Acceptance Scenarios**:

1. **Given** a fresh checkout of this repository on the laptop, **When** the laptop's NixOS
   configuration is built from the repo, **Then** the build succeeds without errors.
2. **Given** the repo's configuration is built, **When** its effective settings are compared
   to the machine's currently running configuration, **Then** they match for every setting
   this feature is scoped to carry over (locale, timezone, networking, desktop environment,
   users, audio, printing) except any deliberately-changed items called out in this spec.

---

### User Story 2 - Configuration organized by concern (Priority: P2)

As the maintainer of this repo, I want settings grouped into separate files by the kind of
thing they configure (e.g., locale/internationalisation, boot, networking, desktop
environment, users, Nix daemon settings), instead of one monolithic file, so that I can find
and change a given setting quickly and reuse the non-laptop-specific pieces when a second
host is added later.

**Why this priority**: Directly enables Constitution Principle III (Host Modularity &
Composability) and makes the repo maintainable as it grows, but the repo is still usable
(just less pleasant to navigate) if this isn't done yet — hence P2, not P1.

**Independent Test**: Inspect the repo layout and confirm that locale settings, boot
settings, networking settings, desktop-environment settings, user-account settings, and Nix
daemon settings each live in their own identifiable module rather than a single
undifferentiated file, and that the laptop's host configuration imports them.

**Acceptance Scenarios**:

1. **Given** the repo after this feature is complete, **When** someone wants to change the
   system locale, **Then** there is a single, clearly-named file responsible for locale
   settings that they can edit without touching unrelated settings.
2. **Given** the repo after this feature is complete, **When** a future feature adds a
   second host, **Then** the shared (non-hardware-specific) modules can be imported by the
   new host without copy-pasting their contents.

---

### User Story 3 - Clean, trustworthy hardware configuration (Priority: P3)

As the maintainer of this repo, I want the committed `hardware-configuration.nix` to be an
accurate, unmodified reflection of what this laptop's hardware scan actually produces, so
that the file remains trustworthy and reproducible rather than carrying manual edits or
stray content of unknown origin.

**Why this priority**: This closes a specific, already-identified problem (see Assumptions)
that undermines Constitution Principles I and II, but it's a narrower, more mechanical fix
than User Stories 1–2, so it's lower priority even though it should still ship in this
feature.

**Independent Test**: Diff the repo's `hardware-configuration.nix` against a fresh
`nixos-generate-config` run (or against the machine's live `/etc/nixos/hardware-configuration.nix`,
adjusted only for known-intentional differences) and confirm there are no unexplained
manual additions.

**Acceptance Scenarios**:

1. **Given** the repo's `hardware-configuration.nix`, **When** it is inspected, **Then** it
   contains only content a hardware scan would generate plus any explicitly-documented,
   intentional additions — no unexplained fetches, network calls, or leftover edits.

---

### Edge Cases

- What happens if a setting currently active on the running machine (e.g., SSH password
  authentication — see Assumptions) is ambiguous about whether it should be preserved as-is
  or tightened as part of "fixing issues"? This spec resolves that ambiguity explicitly
  rather than leaving it implicit (see clarified Functional Requirements below).
- What happens if the repo's configuration, once built, would change something
  operationally significant (e.g., hostname) versus the currently running system? The
  change must be visible and intentional in this spec, not a silent side effect of
  reorganizing files.
- How is content in `hardware-configuration.nix` that does not correspond to anything a
  hardware scan or documented manual step would produce (the injected
  `(fetchTarball "https://github.com")` import found in the current repo copy) handled? It
  MUST be removed as part of this feature, not carried forward.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST provide a `hardware-configuration.nix` for the laptop host
  that matches what `nixos-generate-config` produces for this machine, with no manual
  additions of unknown origin. In particular, the previously-present
  `(fetchTarball "https://github.com")` entry in the imports list, and the fabricated
  `services.nixos-vscode-server.enable = true;` line (not a real NixOS option and not present
  on the machine's actual `/etc/nixos/hardware-configuration.nix` — discovered during
  implementation), MUST be removed.
- **FR-002**: The repository MUST define a flake (`flake.nix` plus a committed
  `flake.lock`) that can evaluate and build a complete NixOS configuration for the laptop
  host, per Constitution Principle II (Reproducibility & Pinned Inputs).
- **FR-003**: The laptop's configuration MUST be organized into separate modules grouped by
  concern, at minimum: locale/internationalisation, boot/bootloader, networking, desktop
  environment (including display manager and input/keyboard layout), user accounts, audio,
  printing, and Nix daemon settings — rather than one combined file.
- **FR-004**: The configuration MUST carry forward the following settings currently active
  on the machine, unless a Functional Requirement below explicitly changes them: locale
  `en_AU.UTF-8` (including the per-category `LC_*` overrides), timezone
  `Australia/Melbourne`, NetworkManager-based networking, KDE Plasma 6 desktop with SDDM
  display manager, `au` X11 keyboard layout, CUPS printing, Pipewire-based audio (PulseAudio
  compatibility layer disabled in favor of Pipewire), the `dmiller` user account with
  `networkmanager` and `wheel` groups, Firefox installed, `nixpkgs.config.allowUnfree =
  true`, and `system.stateVersion = "26.05"`.
- **FR-005**: The Nix daemon settings currently reflected in the machine-generated
  `/etc/nix/nix.conf` MUST instead be expressed declaratively via the NixOS `nix.settings`
  module option in the repo, so they are reproduced from source rather than depended on as
  machine-local state.
- **FR-006**: This feature's scope MUST be system-level (NixOS) configuration only; per-user
  environment management (home-manager) is out of scope for this feature and is deferred to
  a later feature.
- **FR-007**: The laptop's NixOS hostname MUST remain `nixos` for this feature; renaming the
  host is deferred to a later feature (e.g., when the desktop host is introduced and
  distinct host identifiers become necessary).
- **FR-008**: SSH password authentication MUST remain enabled, preserving current login
  behavior; tightening SSH authentication (e.g., requiring keys only) is deferred to a
  dedicated security-focused feature rather than being bundled into this initial setup.
- **FR-009**: The resulting configuration MUST successfully evaluate and dry-build (e.g.,
  `nix flake check` and a dry-activate/build for the laptop host) before this feature is
  considered complete, per Constitution Principle IV.
- **FR-010**: The module structure MUST be organized so that settings not specific to this
  laptop's hardware can be imported by a future second host without duplication, per
  Constitution Principle III.
- **FR-011**: The configuration MUST declaratively install `git` and the Claude Code CLI
  (`claude`), available on `PATH` for the `dmiller` user after a build, per Constitution
  Principle I (Declarative Configuration Only) — both are currently present on this machine
  but not declared anywhere in this repo's configuration.

### Key Entities

- **Host Configuration**: The complete NixOS configuration for one physical machine (currently
  just the laptop); composed of the host's hardware scan output plus the shared concern
  modules it imports.
- **Concern Module**: A single-purpose configuration unit for one category of settings (e.g.,
  locale, boot, networking, desktop, users, audio, printing, Nix daemon settings) that a
  Host Configuration imports; designed to be reusable by future hosts where the setting
  isn't hardware- or host-specific.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The laptop's configuration builds successfully from a clean checkout of the
  repository on the first attempt, with zero manual out-of-repo edits required.
- **SC-002**: Every setting listed in FR-004 as carried over is present and correct in the
  repo's configuration, verified by comparing the built configuration's effective values
  against the machine's current running values (100% match on the listed settings).
- **SC-003**: A person unfamiliar with the repo can locate the file responsible for any one
  of locale, boot, networking, desktop, users, audio, printing, or Nix daemon settings in
  under 30 seconds by filename/directory alone (no need to search file contents).
- **SC-004**: The repo's `hardware-configuration.nix` contains zero lines that do not
  correspond to actual hardware-scan output or an explicitly documented intentional
  addition.
- **SC-005**: Immediately after a fresh build from the repo, both `git` and `claude` run
  successfully from a new shell with no manual install step.

## Assumptions

- "The original nix.conf" refers to the machine's existing `/etc/nixos/configuration.nix`
  (the main NixOS system configuration file), not the machine-generated
  `/etc/nix/nix.conf`. The latter is derived automatically from NixOS's `nix.*` options and
  is addressed via FR-005 rather than being copied directly.
- The repository's current `hardware-configuration.nix` contains an unexplained,
  non-functional import — `(fetchTarball "https://github.com")` — that does not appear in
  the machine's actual `/etc/nixos/hardware-configuration.nix` and does not correspond to
  any legitimate hardware-scan output or documented manual step. This is treated as a defect
  to remove (FR-001), not as intentional configuration to preserve.
- During implementation, a second fabricated line was found alongside it:
  `services.nixos-vscode-server.enable = true;`. It is not a real NixOS option (it requires
  an external module not shipped by nixpkgs — confirmed by evaluation failure) and, like the
  `fetchTarball` line, does not appear on this machine's actual
  `/etc/nixos/hardware-configuration.nix`. It is treated the same way: removed as a defect
  (FR-001), not relocated as genuine configuration. Only `services.openssh` in that same
  block is confirmed genuine (present on the real machine) and is relocated per FR-008.
- This feature covers the laptop (the current device) only. Desktop-host support, and any
  shared-vs-host-specific restructuring that can only be validated once a second host
  exists, are deferred to a later feature, consistent with Constitution Principle V
  (Simplicity & Incremental Change).
- Secrets management (e.g., `sops-nix`/`agenix`) is out of scope for this feature; nothing in
  the current configuration requires it yet.
- The existing `dmiller` user's installed package (`kdePackages.kate`) and Firefox are
  carried forward as-is. The only package additions in scope for this feature are `git` and
  the Claude Code CLI (FR-011), both already in use on this machine imperatively (outside
  any declarative config); no other package additions or removals are in scope.
