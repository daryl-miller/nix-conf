# Phase 0 Research: Initial Minimum Environment Setup

The spec (see `spec.md` Assumptions) already resolved the feature-scope ambiguities
(home-manager deferred, hostname unchanged, SSH auth unchanged). What remains here are the
technical/structural decisions needed to implement FR-001 through FR-010.

## Decision 1: Directory layout — `hosts/<name>/` + `modules/nixos/<concern>.nix`

- **Decision**: Host entrypoints and machine-generated hardware files live under
  `hosts/<name>/`; every setting that isn't hardware-specific lives in its own file under
  `modules/nixos/`, grouped by concern (locale, boot, networking, desktop, users, audio,
  printing, Nix daemon settings, remote-dev).
- **Rationale**: Directly satisfies FR-003 (grouped by concern) and FR-010 / Constitution
  Principle III (reusable by a future second host without duplication), while keeping
  `hosts/laptop/hardware-configuration.nix` untouched and never shared, per FR-001.
- **Alternatives considered**:
  - *Single monolithic `configuration.nix`* — rejected: fails FR-003 directly and is the
    exact problem this feature exists to fix.
  - *A `profiles`/role-composition abstraction (e.g., "laptop-profile", "desktop-profile")*
    — rejected for now: only one host exists, so any such abstraction would be guessed
    rather than derived from two real hosts, violating Constitution Principle V. Revisit
    when the desktop host is actually added.

## Decision 2: Flake shape — one `nixosConfigurations.laptop` output

- **Decision**: `flake.nix` declares a single `nixpkgs` input and one
  `nixosConfigurations.laptop` output pointing at `hosts/laptop/configuration.nix`.
- **Rationale**: Satisfies FR-002 with the minimum needed for one host today. The flake
  output is named `laptop` — distinct from the OS-level hostname, which FR-007 keeps as the
  current `nixos` — so the repo has a stable, human-meaningful identifier for this machine
  independent of the (deliberately deferred) hostname decision.
- **Alternatives considered**:
  - *Name the output `nixos` to match the current hostname* — rejected: confusing once a
    second host exists, especially since that host's hostname might also default to
    something generic.
  - *Use `flake-utils` or a multi-system/multi-host generator abstraction* — rejected as
    premature per Constitution Principle V; only one system architecture and one host are
    in scope.

## Decision 3: Relocate `services.openssh` out of `hardware-configuration.nix`; remove the fabricated `services.nixos-vscode-server` line

- **Decision**: Move `services.openssh` into a new `modules/nixos/remote-dev.nix`, imported
  by `hosts/laptop/configuration.nix`, with identical values (`services.openssh.enable = true`,
  `services.openssh.settings.PasswordAuthentication = true`).
- **Correction during implementation**: this decision originally also planned to relocate
  `services.nixos-vscode-server.enable = true`. Running `nix flake check` against a pinned
  `nixpkgs` showed `services.nixos-vscode-server` is not a real NixOS option — it requires an
  external module nixpkgs doesn't ship — and re-checking the earlier diff against this
  machine's actual `/etc/nixos/hardware-configuration.nix` confirms that line isn't present
  there either. It is a second fabricated addition, not genuine configuration, so it was
  removed outright in Foundational (T004) rather than relocated here.
- **Rationale**: `hardware-configuration.nix`'s own header states it is machine-generated
  and "may be overwritten" — it must match real `nixos-generate-config` output (FR-001).
  `services.openssh` is confirmed genuine (present on the real machine) but doesn't belong in
  a generated file; relocating (not deleting) it preserves current behavior per FR-008.
- **Alternatives considered**:
  - *Delete `services.openssh` too* — rejected: would silently disable working SSH access,
    which the spec explicitly says must not happen silently.
  - *Leave `services.openssh` in `hardware-configuration.nix`* — rejected: directly
    contradicts FR-001 and User Story 3's acceptance criteria.
  - *Add the external `nixos-vscode-server` flake input to make the fabricated option real*
    — rejected: nothing in the spec asked for VS Code Remote-SSH support, and the setting
    doesn't reflect the actual running machine; adding a new input to accommodate fabricated
    content would be scope creep, not a fix.

## Decision 4: Remove the injected `(fetchTarball "https://github.com")` import

- **Decision**: Delete the line outright; no replacement.
- **Rationale**: FR-001 and the pre-existing defect noted in the spec's Assumptions. The
  call is non-functional (an incomplete URL that is not a valid tarball source) and
  corresponds to no legitimate hardware-scan output or documented manual step.
- **Alternatives considered**: None — this is defect removal, not a design choice.

## Decision 5: Express current Nix daemon settings via `nix.settings`

- **Decision**: Add `modules/nixos/nix-settings.nix` setting `nix.settings` (and
  `nixpkgs.config.allowUnfree = true`) to reproduce the values currently only present as
  generated output in `/etc/nix/nix.conf` (e.g., default `allowed-users`), so they come from
  the repo rather than machine-local state.
- **Rationale**: FR-005 and Constitution Principle I — nothing about the running system's
  configuration should depend on files this repo doesn't generate.
- **Alternatives considered**: *Leave `/etc/nix/nix.conf` unmanaged* — rejected: directly
  contradicts FR-005.

## Decision 6: Declare `git` and Claude Code CLI via `environment.systemPackages`

- **Decision**: Add `modules/nixos/dev-tools.nix` with
  `environment.systemPackages = [ pkgs.git pkgs.claude-code ];`, imported by
  `hosts/laptop/configuration.nix`.
- **Rationale**: FR-011. Both tools are already installed and in active use on this machine
  (`git` 2.55.0, `claude` from a `claude-code` derivation) but neither is declared anywhere
  in this repo — a direct instance of the drift Constitution Principle I exists to prevent.
  `environment.systemPackages` (rather than a per-user package list or home-manager) matches
  how the existing `dmiller`-scoped tool (`kdePackages.kate`) and desktop-level tools
  (Firefox) are otherwise declared in this feature, and needs no home-manager, which FR-006
  defers.
- **Alternatives considered**:
  - *Per-user `users.users.dmiller.packages`* — rejected: these are general-purpose CLI
    tools useful in any shell/session on this single-user machine, not something meaningfully
    scoped to one user account the way `kate` was in the original config.
  - *`programs.git.enable`* (the NixOS module that also manages global git config) — not
    used here: no global git config values (`user.name`, `user.email`, aliases, etc.) were
    specified as in scope for this feature; only "make git available" was requested.
    Configuring git identity/behavior declaratively can be a follow-up feature.
  - *home-manager* — rejected per FR-006 (explicitly deferred).

**Output**: All technical unknowns needed for Phase 1 design are resolved above; no
`NEEDS CLARIFICATION` markers remain in the Technical Context.
