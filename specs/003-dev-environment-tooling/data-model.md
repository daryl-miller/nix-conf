# Phase 1 Data Model: Developer Environment Tooling

This feature has no application data; the "entities" below are the configuration units this
feature introduces or extends (see spec.md Key Entities), scoped to make module boundaries
and ownership unambiguous during implementation. It extends the Host Configuration / Concern
Module model established in `specs/001-initial-environment-setup/data-model.md` with a
parallel, per-user tier.

## Home Configuration (new)

Represents the complete home-manager configuration for one user on one host — the per-user
analogue of a Host Configuration.

| Field | Description |
|---|---|
| `user` | The system user this configuration applies to (e.g., `dmiller`). |
| `home.nix` | Per-user entrypoint (`modules/home/<user>.nix`): sets `home.stateVersion` and imports the Home Concern Modules this user needs. |

**Instances in this feature**: exactly one — `dmiller` on `laptop`, wired via
`home-manager.users.dmiller = import ../home/dmiller.nix;` in the new
`modules/nixos/home-manager.nix`.

**Validation rule**: A Home Configuration MUST NOT duplicate settings owned by a System
Concern Module (e.g., which shell binary is installed, or Docker group membership) — those
stay system-level (see mapping below); a Home Configuration only owns the user's own
program configuration (dotfile-equivalent settings).

## Home Concern Module (new)

A single-purpose Nix file under `modules/home/` owning one category of per-user settings,
importable by any Home Configuration that needs it — the per-user analogue of a (System)
Concern Module from feature 001.

| Field | Description |
|---|---|
| `name` | Filename identifying the concern (`shell`, `editor`, `tmux`, `github`). |
| `settings owned` | The specific `programs.*` option paths this module is responsible for (see table below). |
| `host/user-specific?` | No — by construction, nothing host- or user-identity-specific lives here; that stays in the Home Configuration entrypoint (e.g., `modules/home/dmiller.nix`). |

**Validation rule**: Each setting from FR-003/FR-004/FR-005/FR-006 is owned by exactly one
Home Concern Module — no setting is duplicated across modules (mirrors the System Concern
Module validation rule from feature 001).

### Home Concern Module → settings mapping (from FR-003–FR-006, FR-004a, and research.md Decisions 4–6)

| Module | Settings owned |
|---|---|
| `shell.nix` | `programs.zsh.enable`, `programs.zsh.autosuggestion.enable`, `programs.zsh.syntaxHighlighting.enable`, `programs.zsh.enableCompletion`, `programs.zsh.shellAliases` (`ls`/`grep`/`diff` color), `programs.fzf.enable`, `programs.fzf.enableZshIntegration`, `programs.starship.enable`, `programs.starship.enableZshIntegration` |
| `editor.nix` | `programs.neovim.enable` |
| `tmux.nix` | `programs.tmux.enable` |
| `github.nix` | `programs.gh.enable`, `home.packages` (`ghstack`) |

## System Concern Module extensions (existing modules, new settings)

Extends the Concern Module table from `specs/001-initial-environment-setup/data-model.md`.
No new System Concern Module files are added except `home-manager.nix`; existing files gain
settings.

| Module | Settings added by this feature |
|---|---|
| `dev-tools.nix` | `environment.systemPackages` += `dotnet-sdk`, `dotnet-aspnetcore`, `dotnet-ef`, `csharpier`, `go`, `awscli2`, `aws-sso-cli`, `terraform`, `nodejs`, `python3`, `kubectl`, `k3d`; `virtualisation.docker.enable` |
| `users.nix` | `users.users.dmiller.extraGroups` += `"docker"`; `users.users.dmiller.shell = pkgs.zsh` |
| `remote-dev.nix` | `programs.nix-ld.enable` |
| `home-manager.nix` *(new file)* | `home-manager.useGlobalPkgs`, `home-manager.useUserPackages`, `home-manager.users.dmiller` (points to the Home Configuration) |

**Validation rule**: `home-manager.nix` owns only the wiring between the system config and a
user's Home Configuration — it MUST NOT declare `programs.*` (home-manager) options directly;
those belong in Home Concern Modules, keeping the same one-setting-one-owner rule as every
other Concern Module.

## Flake Input (new)

| Field | Description |
|---|---|
| `name` | `home-manager` |
| `source` | `github:nix-community/home-manager` |
| `follows` | `inputs.nixpkgs.follows = "nixpkgs"` — shares this repo's existing pinned `nixpkgs`, per Constitution Principle II. |

**Validation rule**: Pinned via the committed `flake.lock`, updated only through a deliberate
`nix flake update home-manager` (or whole-flake update), never hand-edited (Constitution
Principle II).
