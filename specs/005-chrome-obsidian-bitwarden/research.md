# Phase 0 Research: Chrome, Obsidian & Bitwarden Desktop Apps

## Decision: Package names and attributes

- **Decision**: Use the `nixpkgs` attributes `google-chrome`, `obsidian`, and
  `bitwarden-desktop`.
- **Rationale**: Verified directly against the pinned `nixpkgs` flake input
  (`nix eval nixpkgs#<attr>.meta.unfree`):
  - `google-chrome` exists, `meta.unfree = true`.
  - `obsidian` exists, `meta.unfree = true`.
  - `bitwarden-desktop` exists, `meta.unfree = false` (source-available/free license).
  - The older attribute `bitwarden` is a removed/renamed alias that now throws an error
    pointing at `bitwarden-desktop` — confirming `bitwarden-desktop` is the current,
    correct attribute for the desktop app (not the `bitwarden-cli` package, which is a
    separate attribute for the command-line tool and is out of scope per spec
    Assumptions).
- **Alternatives considered**:
  - `chromium` instead of `google-chrome`: rejected — the spec explicitly asks for
    "Chrome" (Google's branded build with sync/Chrome-only features), not the open-source
    Chromium base.
  - `ungoogled-chromium`: rejected for the same reason — the developer wants Chrome
    specifically, not a privacy-hardened Chromium fork.
  - A Bitwarden browser extension instead of/in addition to the desktop app: rejected —
    the feature spec explicitly scopes to the desktop application only (spec
    Assumptions); an extension can be added as a separate, later feature if wanted.

## Decision: Unfree package handling

- **Decision**: No new `nixpkgs.config` changes are needed.
- **Rationale**: `modules/nixos/nix-settings.nix` already sets
  `nixpkgs.config.allowUnfree = true` globally, which covers `google-chrome` and
  `obsidian` (both unfree). `bitwarden-desktop` doesn't even require this, but is
  unaffected by it being set.
- **Alternatives considered**: Per-package allow-listing via
  `nixpkgs.config.allowUnfreePredicate`: rejected as unnecessary complexity (Constitution
  Principle V) — the repo has already made the simpler blanket choice, and there's no
  stated reason to depart from it for these three packages.

## Decision: Module placement

- **Decision**: Add a new NixOS module, `modules/nixos/desktop-apps.nix`, exposing the
  three packages via `environment.systemPackages`, imported from
  `hosts/laptop/configuration.nix`.
- **Rationale**: Mirrors the existing, working pattern in `modules/nixos/dev-tools.nix`
  (a flat list of `environment.systemPackages`) rather than inventing a new mechanism.
  Keeping it in its own file (rather than appending to `dev-tools.nix` or `users.nix`)
  separates "general desktop applications" from "developer toolchains" and from
  "per-user account definition," consistent with Constitution Principle III (Host
  Modularity & Composability) — a future second host (or a future decision to drop one of
  these apps) can toggle this module independently.
- **Alternatives considered**:
  - Appending to `modules/nixos/dev-tools.nix`: rejected — these are general desktop
    applications, not developer toolchain packages; mixing concerns makes the module
    harder to reason about and reuse selectively.
  - Home-manager `home.packages` in `modules/home/dmiller.nix` (or a new home module):
    rejected — the existing precedent for installed GUI/CLI applications used by
    `dmiller` (`vscode`, `claude-code`, etc.) is `environment.systemPackages` in
    `dev-tools.nix`, plus one user-scoped package (`kdePackages.kate`) directly under
    `users.users."dmiller".packages` in `users.nix`. Since none of these three apps need
    per-user home-manager configuration (dotfiles, declarative settings) beyond being
    installed and launchable, a system package is the simpler, more consistent choice per
    Constitution Principle V. If per-user declarative configuration for one of these apps
    becomes wanted later (e.g., an Obsidian config vault template), it can move to
    home-manager at that time.

## Decision: Application data persistence

- **Decision**: No special handling is added; each application manages its own user data
  under `dmiller`'s `$HOME` (e.g., `~/.config/google-chrome`, an Obsidian vault directory
  the user chooses, `~/.config/Bitwarden`), which already persists across rebuilds like
  the rest of `$HOME` on this system.
- **Rationale**: This system does not use an impermanence/ephemeral-root scheme that
  would wipe `$HOME` on rebuild or reboot; user data under `$HOME` is already durable.
  Nothing in this feature changes that.
- **Alternatives considered**: None — this is a direct consequence of the existing host
  setup, not a new choice this feature needs to make.

## Decision: Validation approach

- **Decision**: Validate via `nix flake check` plus `nixos-rebuild dry-activate
  --flake .#laptop` (Constitution Principle IV, matching prior features' pattern), then
  manually launch each of the three applications from the desktop environment to confirm
  the acceptance scenarios in `spec.md`.
- **Rationale**: No test framework applies to a declarative package addition; the
  meaningful validation is that the configuration evaluates/builds and that each
  application actually launches and behaves as expected post-rebuild.
- **Alternatives considered**: Automated UI testing of each application: rejected as
  disproportionate for "install three off-the-shelf desktop applications" — out of step
  with Constitution Principle V, and these are third-party applications, not
  repo-authored logic.
