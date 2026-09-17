<!--
Sync Impact Report
==================
Version change: 1.0.0 → 1.1.0
Modified principles:
  - n/a (no existing principle redefined)
Added principles:
  - VI. Secure by Default (NON-NEGOTIABLE)
Renamed sections:
  - "Secrets & Security Requirements" → "Secrets Management" (narrowed to the secrets-handling
    mechanism; the general security posture it used to imply now lives in Principle VI so it
    carries the same NON-NEGOTIABLE weight as the other Core Principles)
Added sections: none beyond the above
Removed sections: none
Deferred / TODO placeholders: none
Follow-up (non-governance, deferred per Scope Guard — see Next Actions in the command's reply):
  - The laptop host's current SSH configuration (`modules/nixos/remote-dev.nix`,
    `services.openssh.settings.PasswordAuthentication = true`) predates this principle and is
    now a tracked violation requiring remediation, not something to leave indefinitely.
Templates requiring follow-up: none checked in this run (scope limited to constitution per
  command guard) — plan/spec/tasks templates should be reviewed against Principle VI the next
  time they are touched.
-->

# nix-config Constitution

## Core Principles

### I. Declarative Configuration Only
All system and user-level state MUST be expressed in Nix (NixOS modules, home-manager
modules, or flake configuration) and applied via `nixos-rebuild` / `home-manager switch`.
Manual, imperative changes to a machine's configuration (editing files outside the repo,
ad-hoc package installs, hand-edited systemd units, etc.) are prohibited except for
throwaway local debugging that is never relied upon to persist. If a manual change is
needed to unblock work, it MUST be back-ported into the Nix configuration before the task
is considered done.

**Rationale**: The entire point of this repo is that a machine's state can be rebuilt from
source. Any drift between the repo and the running system silently erodes that guarantee
and defeats the purpose of using Nix at all.

### II. Reproducibility & Pinned Inputs
`flake.lock` MUST be committed and MUST NOT be edited by hand. Flake inputs are updated only
via `nix flake update` (whole-flake or scoped to a specific input) as a deliberate, reviewed
change — never as a side effect of another task. Configuration MUST NOT depend on impure
fetches (arbitrary `builtins.fetchurl` outside pinned inputs, unpinned channels, network
access during evaluation) that would make `nix build` produce different results on two
machines given the same lockfile.

**Rationale**: Reproducibility is only real if the inputs are pinned and updates are
intentional. Silent or incidental input drift makes "it works on my laptop" bugs
indistinguishable from real regressions.

### III. Host Modularity & Composability
Configuration is organized so host-specific settings (currently the laptop, later the
desktop) live in per-host files/directories, while shared behavior lives in common modules
that hosts import. A new host MUST be addable by writing host-specific files and importing
existing shared modules — not by forking or duplicating existing host configuration.
`hardware-configuration.nix` and other machine-generated files are treated as host-specific
and are never shared.

**Rationale**: A second machine is already planned. Structuring for composability now is
cheap; retrofitting it after two hosts have diverged is not.

### IV. Build & Validate Before Merge (NON-NEGOTIABLE)
Every change MUST be validated before it is considered complete: at minimum `nix flake
check` and a dry build (`nixos-rebuild build` / `nixos-rebuild dry-activate`, or the
home-manager equivalent for user-level changes) MUST succeed for every affected host. A
change that has not been built MUST NOT be merged or treated as done on the strength of the
diff alone.

**Rationale**: Nix's evaluation errors are cheap to catch and expensive to discover later on
a machine you're depending on (e.g., mid-reboot). This is the one gate that is never
skipped, even for "trivial" edits.

### V. Simplicity & Incremental Change
Prefer the simplest module structure that solves the problem in front of you. Do not build
abstractions (option layers, host-selection frameworks, custom libraries) for a second host,
a future use case, or a hypothetical need until that need actually exists. When the desktop
is onboarded, refactor shared structure out of what by then are two concrete hosts rather
than guessing at the shared shape in advance.

**Rationale**: Premature multi-host abstraction, designed against a single real host, tends
to guess wrong and has to be redone anyway once the second host's real constraints are
known.

### VI. Secure by Default (NON-NEGOTIABLE)
Every host MUST follow current security best practice by default, not as an opt-in. In
particular:

- Remote and administrative authentication (SSH and equivalents) MUST use key-based (or
  stronger, e.g., hardware-token) authentication. Password-based authentication for such
  access MUST NOT be enabled.
- A setting that weakens the system's security posture (permissive firewall rules, disabled
  authentication, deprecated/weak ciphers, unnecessary open network services, etc.) MUST NOT
  be introduced without an explicit, documented justification in that change's own spec or
  plan — the same bar Principle V sets for complexity, applied to security.
- An existing configuration that violates this principle (whether present before this
  principle was adopted or introduced later by mistake) is a tracked defect, not a permanent
  exception. It MUST be recorded (e.g., as a spec Assumption or a follow-up feature) with a
  concrete remediation path, not silently carried forward feature after feature.

**Rationale**: A personal system's biggest security risk is usually a convenience default
nobody revisited (e.g., password SSH auth left on "to keep things working"). Making security
a Core Principle — instead of a one-off checklist item — means every future change is
checked against it the same way it's checked against reproducibility or simplicity, and
known weaknesses have to be named and tracked rather than quietly re-shipped.

## Secrets Management

Secrets (passwords, API tokens, private keys, WireGuard/VPN keys, etc.) MUST NOT be
committed to this repository in plaintext, including in Nix files, comments, or shell
history captured into configuration. Secrets MUST be managed through an encrypted-at-rest
mechanism (e.g., `sops-nix` or `agenix`) once any secret is needed; until such a mechanism
is introduced, configuration requiring a secret is left as a documented placeholder rather
than filled in with a real value. Public SSH keys, non-sensitive hostnames, and similar
public identifiers are not considered secrets. (This section covers the *mechanism* for
handling secrets; the general security posture it supports is governed by Principle VI.)

## Development Workflow

Non-trivial changes — adding a new host, restructuring shared modules, introducing a new
class of service (e.g., first-time secrets management, first desktop environment) — SHOULD
go through the Spec Kit workflow (`/speckit-specify` → `/speckit-plan` → `/speckit-tasks` →
`/speckit-implement`) so the change is reviewed against these principles before it lands.
Small, self-contained edits (bumping a package version, tweaking an existing option) MAY be
made directly, but are still subject to Principle IV (build & validate before merge).

## Governance

This constitution supersedes ad-hoc practice for this repository. Amendments are made via
the `/speckit-constitution` command, which MUST regenerate the Sync Impact Report at the top
of this file and MUST bump the version according to semantic versioning:

- **MAJOR**: A principle is removed or redefined in a way that is backward-incompatible with
  prior practice.
- **MINOR**: A new principle or section is added, or existing guidance is materially
  expanded.
- **PATCH**: Wording, clarification, or typo fixes with no semantic change.

Every non-trivial change (see Development Workflow) SHOULD be checked against these
principles before being treated as complete, with Principles IV and VI enforced without
exception. Complexity that appears to violate Principle V (Simplicity & Incremental Change),
or a security weakening that appears to violate Principle VI (Secure by Default), MUST be
justified in the change's own plan/spec rather than silently introduced.

**Version**: 1.1.0 | **Ratified**: 2026-09-12 | **Last Amended**: 2026-09-12
