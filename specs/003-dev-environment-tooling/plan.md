# Implementation Plan: Developer Environment Tooling

**Branch**: `003-dev-environment-tooling` | **Date**: 2026-09-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-dev-environment-tooling/spec.md`

## Summary

Give the `dmiller` user on the laptop a complete polyglot development environment by:
(1) declaring system-wide language/platform toolchains — .NET SDK, AWS CLI, Terraform,
Docker (daemon + group membership), Node.js, and Python — in `modules/nixos/dev-tools.nix`;
(2) introducing `home-manager` as a NixOS module (new flake input, tracking `nixpkgs`) so
per-user environment state (shell, editor, multiplexer) is declared alongside system
configuration and applied by the same `nixos-rebuild switch`; (3) configuring zsh (default
login shell) with fuzzy history/file search (`fzf`) and a curated, native home-manager
plugin set (autosuggestions, syntax highlighting, completion) instead of a heavier framework
like oh-my-zsh; (4) declaring Neovim and tmux for `dmiller`; and (5) enabling `nix-ld` so the
VS Code Remote-SSH extension's auto-downloaded server binary runs correctly on NixOS over the
existing hardened SSH connection, with no new listening service or authentication path.

## Technical Context

**Language/Version**: Nix expression language with flakes enabled; targets the NixOS release
matching `system.stateVersion = "26.05"` (unchanged by this feature).

**Primary Dependencies**: `nixpkgs` (existing pinned input) providing `dotnet-sdk` (.NET 8
LTS), `awscli2`, `terraform`, `docker`, `nodejs`, `python3`, `neovim`, `tmux`, `fzf`,
`zsh-autosuggestions`, `zsh-syntax-highlighting` — all confirmed present in the currently
pinned `nixpkgs` revision (see research.md). New flake input: `home-manager`
(`github:nix-community/home-manager`, `inputs.nixpkgs.follows = "nixpkgs"`) for per-user
configuration.

**Storage**: N/A — this is system/user configuration, not an application with data storage.

**Testing**: `nix flake check` for evaluation correctness, plus a dry build
(`nixos-rebuild dry-activate --flake .#laptop` / `nixos-rebuild build --flake .#laptop`),
which now also evaluates the `home-manager.users.dmiller` activation package — the build gate
required by FR-011 / Constitution Principle IV.

**Target Platform**: NixOS on this laptop — `x86_64-linux` (unchanged from feature 001).

**Project Type**: Single project — a Nix flake system-configuration repository
(infrastructure-as-code), not an application with a src/tests split.

**Performance Goals**: N/A — no runtime performance target; only that `nix flake check` /
dry-activate completes without error in normal `nixos-rebuild` time.

**Constraints**: Must build reproducibly from pinned inputs alone (Constitution Principle
II — `home-manager` is added as a pinned, `nixpkgs`-following input, not an impure fetch);
must not weaken the SSH posture from specs/002-harden-ssh-access (Constitution Principle VI
/ FR-008); must require zero manual out-of-repo setup after a successful build (SC-001,
SC-002, SC-005).

**Scale/Scope**: One host (laptop), one user (`dmiller`). Home-manager module layout must
not force duplication when a second host or user is added later (Constitution Principle III)
but must not pre-build user-selection abstractions only a second user/host could validate
(Constitution Principle V).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle / Section | Check | Result |
|---|---|---|
| I. Declarative Configuration Only | Every toolchain, shell/editor/multiplexer setting, and the `nix-ld` enablement is expressed in Nix modules (system `environment.systemPackages`/`virtualisation.docker`/`programs.nix-ld`, and home-manager `programs.*`); nothing depends on a hand-run install step. | PASS |
| II. Reproducibility & Pinned Inputs | The one new flake input, `home-manager`, is pinned via `flake.lock` and follows the existing `nixpkgs` input; VS Code Server's own binary is fetched by the VS Code client at connection time (outside this repo's build), not by Nix evaluation — `nix-ld` only makes that already-external binary runnable, it does not fetch it. | PASS |
| III. Host Modularity & Composability | New `modules/home/<concern>.nix` files (`shell.nix`, `editor.nix`, `tmux.nix`) mirror the existing `modules/nixos/<concern>.nix` granularity and are imported by a per-user aggregator (`modules/home/dmiller.nix`), reusable by a future second host/user without duplication. | PASS |
| IV. Build & Validate Before Merge (NON-NEGOTIABLE) | FR-011 requires `nix flake check` + dry-activate/build (now covering the home-manager activation) to pass before the feature is done; quickstart.md is exactly that check. | PASS |
| V. Simplicity & Incremental Change | Home-manager is wired as a NixOS module (one `nixos-rebuild switch`, not a second standalone command) since there is one user on one host; zsh plugins use home-manager's native options instead of adding an oh-my-zsh framework; VS Code Server support uses the existing built-in `programs.nix-ld` option instead of adding an extra community flake input — no abstraction is built for a hypothetical second user/host. | PASS |
| VI. Secure by Default (NON-NEGOTIABLE) | No SSH setting changes; `nix-ld` adds no listening service or authentication path — VS Code's server process is spawned over the already-hardened SSH connection from specs/002-harden-ssh-access (FR-008). Docker group membership is a routine, documented privilege (equivalent to root via `docker.sock`), not a new remote-facing weakening. | PASS |
| Secrets Management | No secret is introduced or required by this feature. | PASS |
| Development Workflow | This new class of configuration (first home-manager usage, first container runtime) is going through the full Spec Kit workflow, as the constitution recommends for non-trivial changes. | PASS |

No violations — Complexity Tracking is not needed.

## Project Structure

### Documentation (this feature)

```text
specs/003-dev-environment-tooling/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

No `contracts/` directory: as with features 001 and 002, this repository has no external
API/CLI/UI surface for other systems or users to integrate against. The VS Code remote
connection in this feature consumes an existing external interface (SSH, hardened in feature
002) rather than exposing a new one this repo defines.

### Source Code (repository root)

```text
flake.nix                          # + home-manager input, + home-manager.nixosModules.home-manager
flake.lock                         # + pinned home-manager revision (committed)

hosts/
└── laptop/
    ├── configuration.nix          # unchanged: imports hardware-configuration.nix + modules/nixos/*
    └── hardware-configuration.nix # unchanged

modules/
├── nixos/
│   ├── dev-tools.nix              # + dotnet-sdk, awscli2, terraform, nodejs, python3,
│   │                               #   virtualisation.docker.enable, dmiller -> "docker" group
│   ├── remote-dev.nix             # + programs.nix-ld.enable = true (VS Code Server support)
│   ├── users.nix                  # + users.users.dmiller.shell = pkgs.zsh
│   ├── home-manager.nix           # NEW: wires home-manager module, useGlobalPkgs/useUserPackages,
│   │                               #   home-manager.users.dmiller = import ../home/dmiller.nix
│   └── (locale/boot/networking/desktop/audio/printing/nix-settings unchanged)
└── home/
    ├── dmiller.nix                 # NEW: per-user aggregator (home.stateVersion + imports below)
    ├── shell.nix                   # NEW: programs.zsh (+ autosuggestion, syntaxHighlighting,
    │                               #   completion) and programs.fzf (zsh integration)
    ├── editor.nix                  # NEW: programs.neovim
    └── tmux.nix                    # NEW: programs.tmux
```

**Structure Decision**: Extend the existing `hosts/<name>/` + `modules/nixos/<concern>.nix`
split (from feature 001) with a parallel `modules/home/<concern>.nix` tier for per-user
state, following the same one-concern-per-file convention. `modules/home/dmiller.nix` is the
per-user analogue of `hosts/laptop/configuration.nix`: it names which concern modules apply
to that user. Nothing hardware- or host-specific moves into `modules/home/`; those files stay
reusable by a future second host importing the same user's home configuration, per
Constitution Principle III. No host-selection or multi-user abstraction is introduced ahead
of an actual second host/user, per Principle V.

## Complexity Tracking

*No Constitution Check violations — this section is intentionally empty.*
