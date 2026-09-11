# Implementation Plan: Initial Minimum Environment Setup

**Branch**: `001-initial-environment-setup` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-initial-environment-setup/spec.md`

## Summary

Make this repository the authoritative, buildable source for the laptop's NixOS system by:
(1) introducing a flake that defines a `laptop` NixOS configuration, (2) restoring
`hardware-configuration.nix` to genuine, untouched `nixos-generate-config` output — removing
an injected, non-functional `fetchTarball` import and relocating the two legitimate but
misplaced settings it also contained (SSH access, VS Code Remote-SSH support) into a proper
module, (3) reorganizing the machine's current settings (locale, boot, networking,
desktop, users, audio, printing, Nix daemon settings) out of one monolithic file into
concern-scoped modules that a future second host can reuse without duplication, and (4)
declaring `git` and the Claude Code CLI (`claude`) in the repo, since both are currently
installed imperatively on this machine outside any declarative config.

## Technical Context

**Language/Version**: Nix expression language with flakes enabled; targets the NixOS release
matching the existing `system.stateVersion = "26.05"`.

**Primary Dependencies**: `nixpkgs` (single flake input, pinned via `flake.lock`), providing
the `git` and `claude-code` packages (FR-011). No home-manager — explicitly deferred by spec
FR-006.

**Storage**: N/A — this is system configuration, not an application with data storage.

**Testing**: `nix flake check` for evaluation correctness, plus a dry build
(`nixos-rebuild dry-activate --flake .#laptop` or `nixos-rebuild build --flake .#laptop`) as
the build gate required by FR-009 / Constitution Principle IV.

**Target Platform**: NixOS on this laptop — `x86_64-linux`, Intel CPU (`kvm-intel`),
UEFI boot via `systemd-boot`.

**Project Type**: Single project — a Nix flake system-configuration repository
(infrastructure-as-code), not an application with a src/tests split.

**Performance Goals**: N/A — no runtime performance target; the feature's only build-time
expectation is that `nix flake check` / dry-activate completes without error in normal
`nixos-rebuild` time.

**Constraints**: Must build reproducibly from pinned inputs alone (Constitution Principle
II); must not commit secrets (Constitution "Secrets & Security Requirements"); must require
zero manual out-of-repo edits after a successful build (SC-001).

**Scale/Scope**: One host today (the laptop). Module layout must not force duplication when
a second host (desktop) is added later (Constitution Principle III, FR-010) but must not
pre-build abstractions that only a second host could validate (Constitution Principle V).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle / Section | Check | Result |
|---|---|---|
| I. Declarative Configuration Only | Every carried-over setting and every fix (removing the `fetchTarball` injection, relocating SSH/VS Code settings, declaring the currently-imperative `git`/`claude` installs) is expressed in Nix modules; no manual system mutation is introduced. | PASS |
| II. Reproducibility & Pinned Inputs | Introduces `flake.nix` + committed `flake.lock` pinning `nixpkgs`; no impure fetches (the one impure fetch found, `fetchTarball "https://github.com"`, is being removed, not added). | PASS |
| III. Host Modularity & Composability | Settings split into `modules/nixos/<concern>.nix`, imported by `hosts/laptop`; nothing hardware-specific leaves `hosts/laptop/hardware-configuration.nix`. | PASS |
| IV. Build & Validate Before Merge (NON-NEGOTIABLE) | FR-009 requires `nix flake check` + dry-activate/build to pass before the feature is done; this plan's quickstart is exactly that check. | PASS |
| V. Simplicity & Incremental Change | No multi-host selection framework, no home-manager, no hostname rename, no SSH hardening — all explicitly deferred per spec FR-006/007/008 until a real second host or need exists. | PASS |
| Secrets & Security Requirements | No secret is introduced or required by this feature; none of the carried-over settings are secrets. | PASS |
| Development Workflow | This foundational, repo-structuring change is going through the full Spec Kit workflow, as the constitution recommends for non-trivial changes. | PASS |

No violations — Complexity Tracking is not needed.

## Project Structure

### Documentation (this feature)

```text
specs/001-initial-environment-setup/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

No `contracts/` directory: this repository has no external API/CLI/UI surface for other
systems or users to integrate against — it is a NixOS system configuration consumed only by
`nixos-rebuild`/`nix` on the machines it describes.

### Source Code (repository root)

```text
flake.nix                          # defines nixosConfigurations.laptop, pins nixpkgs
flake.lock                         # pinned input versions (committed)

hosts/
└── laptop/
    ├── configuration.nix          # host entrypoint: imports hardware-configuration.nix
    │                               # + the concern modules below
    └── hardware-configuration.nix # untouched nixos-generate-config output only

modules/
└── nixos/
    ├── locale.nix                 # i18n.defaultLocale + LC_* settings, time.timeZone
    ├── boot.nix                   # systemd-boot + EFI settings
    ├── networking.nix             # networking.networkmanager, hostName
    ├── desktop.nix                # xserver, Plasma 6, SDDM, xkb layout
    ├── users.nix                  # users.users.dmiller + programs.firefox
    ├── audio.nix                  # pipewire, rtkit, pulseaudio.enable = false
    ├── printing.nix                # services.printing
    ├── nix-settings.nix           # nix.settings + nixpkgs.config.allowUnfree
    ├── remote-dev.nix             # services.openssh + services.nixos-vscode-server
    │                               # (relocated out of hardware-configuration.nix)
    └── dev-tools.nix              # environment.systemPackages: git, claude-code
```

**Structure Decision**: Single Nix flake project using a `hosts/<name>/` +
`modules/nixos/<concern>.nix` split (see `research.md` decision 1). `hosts/laptop/` holds
only what is genuinely host-specific (its hardware scan and the top-level import list);
every concern that isn't hardware-specific lives in `modules/nixos/` so it is import-only
reuse for a future `hosts/desktop/`, with no host-selection abstraction built ahead of that
need.

## Complexity Tracking

*No Constitution Check violations — this section is intentionally empty.*
