# Implementation Plan: Chrome, Obsidian & Bitwarden Desktop Apps

**Branch**: `005-chrome-obsidian-bitwarden` | **Date**: 2026-09-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-chrome-obsidian-bitwarden/spec.md`

## Summary

Declaratively install three GUI desktop applications — Google Chrome, Obsidian, and the
Bitwarden desktop app — for `dmiller` on the `laptop` host, launchable from either desktop
session (Plasma6 or Hyprland) immediately after a rebuild, with no imperative install step
and no impact on the existing Firefox installation.

## Technical Context

**Language/Version**: Nix (NixOS module system), `nixpkgs` `nixos-unstable` channel (as
already pinned in `flake.lock`)

**Primary Dependencies**: `nixpkgs` packages `google-chrome`, `obsidian`,
`bitwarden-desktop`

**Storage**: N/A — no repository-managed data store. Each application's user data
(browser profile, Obsidian vault files, Bitwarden local vault cache) lives under
`dmiller`'s `$HOME`, outside the Nix store, and is untouched by this feature.

**Testing**: `nix flake check` and `nixos-rebuild dry-activate --flake .#laptop` (per
Constitution Principle IV), followed by manual launch verification of each application per
`quickstart.md`.

**Target Platform**: NixOS `laptop` host (`x86_64-linux`), SDDM login offering either the
Plasma6 (`modules/nixos/desktop.nix`) or Hyprland (`modules/nixos/hyprland.nix`) session.

**Project Type**: Single NixOS flake configuration (system + home-manager modules) — not a
standalone application.

**Performance Goals**: N/A — standard desktop GUI applications; no custom performance
target beyond normal launch/use responsiveness.

**Constraints**: Must be fully declarative with no imperative install step (Constitution
Principle I); must not remove, disable, or degrade the existing Firefox installation or
other working application (spec FR-005); introduces no new network-exposed service and no
change to authentication posture (Constitution Principle VI).

**Scale/Scope**: Three packages, one host (`laptop`), one user (`dmiller`).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Declarative Configuration Only** — PASS. All three applications are added as
  `nixpkgs` packages referenced from a NixOS module; nothing is installed by hand.
- **II. Reproducibility & Pinned Inputs** — PASS. No new flake inputs are introduced; the
  packages come from the already-pinned `nixpkgs` input. `flake.lock` is not touched.
- **III. Host Modularity & Composability** — PASS. A new, dedicated module
  (`modules/nixos/desktop-apps.nix`) holds these packages, kept separate from
  `dev-tools.nix` (developer toolchains) so a future second host can opt into "desktop
  apps" independently of "dev tools" without duplication.
- **IV. Build & Validate Before Merge** — PASS (planned). `nix flake check` and a dry
  build for `laptop` are required validation steps before this feature is done (see
  `quickstart.md`).
- **V. Simplicity & Incremental Change** — PASS. Three packages in one flat module; no new
  option layer, no abstraction beyond what today's single host needs.
- **VI. Secure by Default** — PASS. No security-relevant setting changes, no new
  network-exposed service. `nixpkgs.config.allowUnfree` is already enabled globally
  (`modules/nixos/nix-settings.nix`); no additional unfree exception is introduced.
- **Secrets Management** — N/A. No secret is introduced or stored in the repository; the
  Bitwarden desktop app authenticates against the developer's own remote Bitwarden
  account, independent of this repo's secrets-handling mechanism.

No violations. Complexity Tracking is not needed.

## Project Structure

### Documentation (this feature)

```text
specs/005-chrome-obsidian-bitwarden/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

No `contracts/` directory: this feature adds no API, CLI surface, or other interface
contract — it only provisions installed GUI applications.

### Source Code (repository root)

```text
modules/nixos/
├── desktop-apps.nix     # NEW — Chrome, Obsidian, Bitwarden desktop packages
├── dev-tools.nix         # existing — developer toolchains (unchanged, for contrast)
└── users.nix             # existing — programs.firefox.enable stays as-is (unchanged)

hosts/laptop/
└── configuration.nix     # add one import line for modules/nixos/desktop-apps.nix
```

**Structure Decision**: This is a single NixOS flake configuration repo, not a
multi-project codebase. The feature adds one new shared NixOS module,
`modules/nixos/desktop-apps.nix`, following the existing pattern set by
`modules/nixos/dev-tools.nix` (a flat `environment.systemPackages` list), and imports it
from `hosts/laptop/configuration.nix`. Keeping "desktop apps" as its own module (rather
than folding into `dev-tools.nix` or `users.nix`) matches Constitution Principle III: it is
a distinct concern from developer toolchains and can be reused or omitted independently
when a second host is onboarded.

## Complexity Tracking

*No violations — this section intentionally left empty.*
