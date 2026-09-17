# Phase 0 Research: Developer Environment Tooling

All package/module names below were confirmed against the repository's actual pinned
`nixpkgs` input (`github:NixOS/nixpkgs/8ce4ef6cb6f871616146b9fe26d2a5ae594e94fe`, per
`flake.lock`) via `nix eval` / source inspection, not assumed from general knowledge.

## Decision 1: Per-user configuration mechanism — home-manager as a NixOS module

**Decision**: Add `home-manager` as a new flake input (`github:nix-community/home-manager`,
tracking `master` to match the `nixos-unstable` `nixpkgs` input already in use, with
`inputs.nixpkgs.follows = "nixpkgs"`), imported via `home-manager.nixosModules.home-manager`
into the laptop's `nixosSystem` module list, and configured with `useGlobalPkgs = true` /
`useUserPackages = true` so it shares the system's `nixpkgs` evaluation rather than
duplicating it.

**Rationale**: Feature 001 explicitly deferred home-manager (its FR-006) until per-user
environment management was actually needed — this feature is that need. Wiring it as a NixOS
module means one `nixos-rebuild switch` activates both system and user state together, which
is simpler than a standalone `home-manager switch` for a single-user, single-host setup
(Constitution Principle V), while `useGlobalPkgs`/`useUserPackages` avoids evaluating
`nixpkgs` twice.

**Alternatives considered**:
- *Standalone home-manager* (separate `home-manager switch` invocation, own `nixpkgs`
  pin): rejected — adds a second build/activation command and a second reproducibility
  surface for no benefit yet; revisit only if a non-NixOS host is ever added.
- *No home-manager; plain `environment.systemPackages` + dotfiles committed and symlinked
  by hand*: rejected outright — symlinking dotfiles imperatively violates Constitution
  Principle I.

## Decision 2: Language/platform toolchains — system-level packages

**Decision**: Add `dotnet-sdk`, `dotnet-aspnetcore`, `dotnet-ef`, `csharpier`, `go`,
`awscli2`, `aws-sso-cli`, `terraform`, `nodejs`, and `python3` to `environment.systemPackages` in the
existing `modules/nixos/dev-tools.nix` (alongside the already-declared `git`/`claude-code`),
and enable `virtualisation.docker.enable = true;` plus
`users.users.dmiller.extraGroups = [ "docker" ]` (merged with the existing
`networkmanager`/`wheel` groups in `modules/nixos/users.nix`) for Docker specifically, since
it needs a running daemon/service rather than just a CLI on `PATH`.

Versions resolved in the pinned `nixpkgs` revision at plan time:

| Package attribute | Resolved version | Provides |
|---|---|---|
| `dotnet-sdk` | 8.0.424 (wrapped) | C#/.NET SDK — FR-001 |
| `dotnet-aspnetcore` | 8.0.30 | ASP.NET Core runtime — FR-001 |
| `dotnet-ef` | 10.0.9 | EF Core CLI (`dotnet ef`) — FR-001 |
| `csharpier` | 1.3.0 | C# code formatter — FR-001 |
| `go` | 1.26.7 | Go toolchain — FR-001 |
| `awscli2` | 2.35.11 | AWS CLI — FR-001 |
| `aws-sso-cli` | 2.3.2 | AWS SSO CLI (https://github.com/synfinatic/aws-sso-cli) — FR-001 |
| `terraform` | 1.16.1 | Terraform CLI — FR-001 |
| `docker` | 29.8.0 | Docker engine/CLI — FR-001, FR-002 |
| `nodejs` | 24.19.0 | Node.js — FR-001 |
| `python3` | 3.14.7 | Python — FR-001 |
| `kubectl` | 1.37.0 | Kubernetes CLI — FR-001 |
| `k3d` | 5.9.0 | Local Kubernetes clusters via Docker — FR-001 |

`dotnet-aspnetcore`, `dotnet-ef`, `csharpier`, `go`, `aws-sso-cli`, `kubectl`, and `k3d` were
added mid-implementation at the developer's request (see spec.md Assumptions); each was
confirmed present in the same pinned `nixpkgs` revision via `nix search`/`nix eval` before
being added, consistent with this feature's practice of verifying package names against the
actual pin rather than assuming them. `k3d` depends on the Docker toolchain already declared
by this same decision, so no additional system service is needed beyond
`virtualisation.docker.enable`.

**Rationale**: These are machine-wide developer tools with no per-user preference involved
(unlike shell/editor choice), so they belong with the existing `git`/`claude-code` pattern in
`dev-tools.nix` rather than home-manager. Docker's daemon is inherently a system-level
service (`virtualisation.docker`), so it must be declared at the NixOS level regardless of
where the CLI ends up.

**Alternatives considered**:
- *Per-project version managers* (e.g., `nvm`, `pyenv`, `asdf`): rejected — the spec's
  Assumptions explicitly scope this feature to one current toolchain version per language via
  the pinned `nixpkgs`; per-project version switching is out of scope and would fight Nix's
  own reproducibility model.
- *Rootless Docker* (`virtualisation.docker.rootless`): rejected per spec Assumptions — no
  stated need for rootless mode; standard rootful mode is simpler and matches typical desktop
  dev use.
- *`docker-compose` as a separate package*: not required by the spec (only "Docker" was
  requested); `docker compose` (the CLI plugin) ships as part of the `docker` package's client
  in current nixpkgs, so no extra package is needed. Verified: no separate action required.

## Decision 3: VS Code Server support — `programs.nix-ld`, not a community module

**Decision**: Enable `programs.nix-ld.enable = true;` in `modules/nixos/remote-dev.nix`
(where SSH/remote-access concerns already live).

**Rationale**: VS Code's Remote-SSH extension downloads a generic-linux, dynamically-linked
server binary onto the target machine over the existing SSH connection and runs it directly —
it is not installed via Nix at all, so there is nothing for this repo to "install" for VS
Code Server itself. That binary fails on NixOS because there is no `/lib64/ld-linux.so.2` or
FHS-standard dynamic linker paths for it to find its shared libraries against.
`programs.nix-ld` is a NixOS module built into the already-pinned `nixpkgs`
(`nixos/modules/programs/nix-ld.nix`, confirmed present in this repo's pinned revision) that
provides exactly that generic dynamic-linker shim, letting unmodified downloaded binaries
(VS Code's server, and similarly-fetched dev tools) run correctly. It requires no new flake
input.

This directly resolves the fabricated-option problem discovered during feature 001
(`services.nixos-vscode-server.enable`, which is not a real NixOS option and required an
external module not shipped by nixpkgs): `nix-ld` is a real, built-in option that solves the
same underlying problem more generally.

**Alternatives considered**:
- *`nix-community/nixos-vscode-server` flake* (the module feature 001 discovered was
  fabricated/not-built-in): would work, but adds an extra flake input and a purpose-built
  systemd path-watcher just to patch one specific vendor's downloaded binary, when `nix-ld`
  is already built into the pinned `nixpkgs` and solves the general "run an unmodified
  downloaded Linux binary on NixOS" problem — rejected per Constitution Principle V
  (simplicity: prefer the built-in, general solution over an extra dependency for a narrower
  one).
- *`openvscode-server` NixOS module* (`services.openvscode-server`, confirmed present in the
  pinned nixpkgs): a different product — a standalone, browser-accessible VS Code server that
  the user connects to directly over HTTP(S), not the client-initiated Remote-SSH flow the
  spec asked for ("connect to the laptop from VS Code's remote development tooling"). Using
  it would mean opening a new network-facing service, which the spec's FR-008 and Constitution
  Principle VI require explicit justification for — rejected since it doesn't match the
  requested workflow and `nix-ld` achieves the actual request without any new service.

## Decision 4: zsh, fuzzy search, and "beneficial plugins" — native home-manager options

**Decision**: In the new `modules/home/shell.nix`:
- `programs.zsh.enable = true;` with `autosuggestion.enable = true;`,
  `syntaxHighlighting.enable = true;`, and `enableCompletion = true;` (home-manager's native
  options, backed by the confirmed-present `zsh-autosuggestions` 0.7.1 and
  `zsh-syntax-highlighting` 0.8.0 packages).
- `programs.fzf.enable = true;` with `enableZshIntegration = true;` (backed by the
  confirmed-present `fzf` 0.74.3 package) for fuzzy history (Ctrl-R), file (Ctrl-T), and
  directory (Alt-C) search.
- `programs.zsh.shellAliases` sets `ls`/`grep`/`diff` to their `--color=auto` forms — a
  zero-dependency way to get colorized common-command output using each tool's own built-in
  color support (all three are GNU coreutils/diffutils already present via the system
  `nixpkgs`), rather than installing a replacement tool.
- `programs.starship.enable = true;` with `enableZshIntegration = true;` (backed by the
  confirmed-present `starship` 1.26.0 package) for a colored, git-aware prompt that shows the
  current branch (and status) by default with no per-project configuration needed.

At the system level, `programs.zsh.enable = true;` is added (required for zsh to be listed in
`/etc/shells`) and `users.users.dmiller.shell = pkgs.zsh;` is set in `modules/nixos/users.nix`
so zsh is `dmiller`'s actual login shell, not just an installed package.

**Rationale**: This satisfies FR-003/FR-004 (shell = zsh, fuzzy search, syntax highlighting,
autosuggestions, completion, colored git-aware prompt, colorized output) using only
home-manager's own maintained options plus one focused, first-class-supported prompt tool —
no third-party plugin manager or framework needed, keeping the plugin set exactly as curated
as the spec's Assumptions describe ("a small, curated set", not an open-ended list). Starship
specifically was chosen over hand-rolling a `PROMPT`/`vcs_info` because it directly satisfies
the developer's ask ("show which branch I'm on") out of the box, in color, and has its own
home-manager module (`programs.starship`) rather than requiring manual zsh scripting.

**Alternatives considered**:
- *`programs.zsh.oh-my-zsh`* (home-manager's oh-my-zsh integration): rejected — pulls in an
  entire framework (themes, dozens of bundled plugins) to get behaviors that home-manager
  already exposes as first-class options; more complexity than the spec's scope calls for
  (Constitution Principle V).
- *`zplug`/`zinit` (manual plugin managers)*: rejected for the same reason — unnecessary
  extra layer when home-manager's built-in options cover every requested capability.
- *Hand-written zsh `vcs_info`/`PROMPT` theming* (for the branch-in-prompt request):
  rejected in favor of Starship — reinventing prompt theming in raw zsh when a
  well-maintained, Nix-native tool already does it is unnecessary complexity for no benefit.
- *`powerlevel10k`*: a popular alternative prompt, but it is a zsh-specific plugin (installed
  via a plugin manager or manually sourced) rather than a standalone binary with a
  home-manager module; Starship achieves the same request more simply and is shell-agnostic
  if the shell ever changes.

## Decision 5: Neovim and tmux — home-manager `programs.*` modules

**Decision**: `programs.neovim.enable = true;` in `modules/home/editor.nix`;
`programs.tmux.enable = true;` in `modules/home/tmux.nix`. Both packages confirmed present
in the pinned `nixpkgs` (`neovim` 0.12.5, `tmux` 3.7c).

**Rationale**: Directly satisfies FR-005/FR-006 with the simplest possible declaration; no
plugin configuration was requested by the spec for either tool, so none is added
(Constitution Principle V — no speculative configuration ahead of an actual stated need).

**Alternatives considered**: None warranted — the spec asks only that both tools be
"installed and available", which these single-line enables fully satisfy.

## Decision 6: GitHub CLI tooling — `programs.gh` plus a plain `ghstack` package

**Decision**: In `modules/home/github.nix` (new Home Concern Module): `programs.gh.enable =
true;` (home-manager's native module, which installs the confirmed-present `gh` 2.100.0
package and manages `~/.config/gh/config.yml`) and `home.packages = [ pkgs.ghstack ];` (the
confirmed-present `ghstack` 0.13.0 package — Meta's stacked-pull-request tool for GitHub).

**Rationale**: `gh` has a genuine home-manager module (`programs.gh`) that also wires up
declarative config, so it's used instead of a bare `environment.systemPackages` install.
`ghstack` has no home-manager module of its own (it's a standalone Python CLI with no shell
integration to wire up), so it's added as a plain package via `home.packages` — the same
`home.packages` mechanism `programs.gh` itself uses under the hood. Both are per-user,
GitHub-workflow tools with no system-wide/multi-user relevance, so they belong in
`modules/home/` (per FR-010) rather than `modules/nixos/dev-tools.nix`, unlike `git` itself
(already system-wide from feature 001, before this per-user tier existed).

**Alternatives considered**:
- *`environment.systemPackages` in `dev-tools.nix`* (matching where `git` lives): rejected —
  `git` predates the home-manager tier (feature 001); now that per-user Git/GitHub tooling
  has a proper home, new additions like `gh`/`ghstack` belong there instead of growing the
  system-wide list further (Constitution Principle III/V).
- *`spr` or `git-branchless`* (other stacked-PR-adjacent tools): not chosen — the developer
  specifically confirmed `ghstack` when asked to disambiguate "stacked PRs cli tool".
