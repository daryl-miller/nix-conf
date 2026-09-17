# Feature Specification: Developer Environment Tooling

**Feature Branch**: `003-dev-environment-tooling`

**Created**: 2026-09-14

**Status**: Draft

**Input**: User description: "Add a comprehensive development environment with tooling for C#/.NET, AWS, Terraform, Docker, Node.js, and Python. Use zsh as the shell with fuzzy search (fzf) and beneficial plugins. Include Neovim, tmux, and support for VS Code Server (remote development)." Extended during implementation: also include Go; round out the C#/.NET toolchain with the ASP.NET Core runtime, the EF Core CLI (`dotnet-ef`), and a formatter (`csharpier`); add an AWS SSO CLI utility (`aws-sso-cli`, https://github.com/synfinatic/aws-sso-cli); add local Kubernetes tooling (`kubectl`, `k3d`); and, for the shell, add the GitHub CLI (`gh`) plus `ghstack` (a stacked-PR tool for GitHub), and a colored, git-aware prompt (Starship) plus colorized `ls`/`grep`/`diff` output.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Work across the full toolchain without manual installs (Priority: P1)

As the developer using this laptop, I want C#/.NET (including ASP.NET Core, the EF Core CLI,
and a formatter), Go, AWS, Terraform, Docker, Node.js, and Python tooling available
immediately after a rebuild, so that I can start any of these kinds of projects without
hand-installing anything first.

**Why this priority**: This is the core value of the feature — everything else (shell,
editor, remote access) is in service of actually being able to do polyglot development work.
Without this, the feature delivers nothing.

**Independent Test**: On a freshly rebuilt system, open a new shell and confirm the .NET SDK
(plus ASP.NET Core runtime, `dotnet ef`, and `csharpier`), Go, AWS CLI, Terraform, Docker,
Node.js, and Python toolchains each run a basic command successfully (e.g., print their
version, or build/run a trivial project) with no additional setup.

**Acceptance Scenarios**:

1. **Given** a freshly rebuilt laptop, **When** the developer opens a new shell, **Then**
   the .NET SDK (with ASP.NET Core runtime, `dotnet ef`, and `csharpier`), Go, AWS CLI,
   Terraform, Docker, Node.js, and Python are all present on `PATH`.
2. **Given** the Docker toolchain is installed, **When** the developer (as `dmiller`) runs a
   container command, **Then** it succeeds without needing to `sudo` or otherwise escalate
   privileges for routine use.

---

### User Story 2 - Productive daily shell (Priority: P2)

As the developer, I want my default shell to be zsh with fuzzy search and a curated set of
productivity plugins, so that day-to-day command-line work (finding past commands, files,
and directories) is fast and pleasant.

**Why this priority**: The shell is used constantly across every other task in this feature,
but the system is still usable with a plain shell while this is being finished — hence P2,
below the toolchains themselves.

**Independent Test**: Open a new interactive session as `dmiller` and confirm the shell is
zsh, fuzzy history/file search works, and the configured plugins (syntax highlighting,
autosuggestions, improved completion) are active — with no manual setup.

**Acceptance Scenarios**:

1. **Given** a freshly rebuilt laptop, **When** `dmiller` opens a new terminal, **Then** the
   shell is zsh and starts with no errors.
2. **Given** the zsh session is open, **When** the developer invokes fuzzy search (e.g., to
   search command history or find a file), **Then** a fuzzy-search interface appears and
   returns matching results.
3. **Given** the zsh session is open, **When** the developer types a command, **Then**
   syntax highlighting and autosuggestions from prior history are visibly active.

---

### User Story 3 - Editing and long-lived terminal sessions (Priority: P3)

As the developer, I want Neovim and tmux available, so that I can edit code and keep
terminal sessions running (and reattach to them later) independent of any single connection.

**Why this priority**: Important for real day-to-day work, but narrower in scope than the
toolchains and shell — a developer can still get by with another editor or a single terminal
window temporarily.

**Independent Test**: Launch Neovim and confirm it opens and edits a file; start a tmux
session, detach, disconnect the terminal entirely, reconnect, and reattach to confirm the
session (including running processes) is preserved.

**Acceptance Scenarios**:

1. **Given** a freshly rebuilt laptop, **When** the developer runs `nvim` on a file, **Then**
   it opens and allows editing and saving.
2. **Given** a tmux session with a running process, **When** the developer detaches,
   disconnects, and later reattaches, **Then** the same session and its running process are
   still there.

---

### User Story 4 - Remote development via VS Code Server (Priority: P4)

As the developer, I want to connect to the laptop from VS Code's remote development tooling,
so that I can code against this machine from a separate client (e.g., another computer)
using my normal editor.

**Why this priority**: Valuable for working remotely, but it depends on the SSH access this
feature does not itself establish (see specs/002-harden-ssh-access) and is used less
frequently than local, in-person development — hence the lowest priority here.

**Independent Test**: From a separate machine, connect to the laptop using VS Code's remote
development feature over SSH, and confirm a full remote session opens (file browsing,
integrated terminal, edit-and-save).

**Acceptance Scenarios**:

1. **Given** the laptop is reachable over SSH as `dmiller` (per specs/002-harden-ssh-access),
   **When** the developer initiates a VS Code remote connection to it, **Then** a working
   remote session opens without additional manual setup on the laptop.
2. **Given** an open remote session, **When** the developer opens an integrated terminal and
   edits/saves a file, **Then** the changes are reflected on the laptop's filesystem.

---

### Edge Cases

- What happens if a project needs a language runtime version older or newer than the one
  provided by the pinned `nixpkgs` input? This feature provides one current version per
  toolchain (see Assumptions); per-project version pinning/switching is out of scope.
- What happens if the Docker daemon isn't running yet when a user tries a container command
  right after boot? The daemon MUST start automatically at boot, not require a manual step.
- What happens when a VS Code remote connection is attempted while SSH key-based
  authentication (per specs/002-harden-ssh-access) has not yet been set up for that client?
  The connection MUST fail the same way a normal SSH login would (no separate, weaker path
  into the machine is introduced for VS Code Server specifically).
- What happens to a tmux session's state across a full laptop reboot? Session state is
  process-backed and MUST NOT be expected to survive a reboot — only disconnect/reconnect of
  the terminal while the machine stays running.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The laptop configuration MUST declaratively provide toolchains for C#/.NET
  (SDK, ASP.NET Core runtime, EF Core CLI, and a formatter), Go, AWS (CLI plus an AWS SSO
  CLI utility), Terraform, Docker, Kubernetes (`kubectl` plus the local-cluster tool `k3d`),
  Node.js, and Python, available on `PATH` for the `dmiller` user immediately after a
  rebuild, with no imperative post-install step.
- **FR-002**: The `dmiller` user MUST be able to run Docker container commands without
  elevating privileges for routine use (e.g., via group membership), and the Docker daemon
  MUST be running and usable immediately after boot.
- **FR-003**: The default interactive shell for `dmiller` MUST be zsh.
- **FR-004**: The zsh configuration MUST provide fuzzy search (history, files, and
  directories) and a curated set of productivity plugins, at minimum: syntax highlighting,
  command autosuggestions, improved tab completion, a colored git-aware prompt showing at
  least the current branch, and colorized output for common commands (`ls`, `grep`, `diff`).
- **FR-004a**: `dmiller` MUST have access to the GitHub CLI (`gh`) and a stacked-pull-request
  tool for GitHub (`ghstack`), available on `PATH` immediately after a rebuild.
- **FR-005**: Neovim MUST be installed and available to `dmiller` as an editor.
- **FR-006**: tmux MUST be installed and available to `dmiller`, supporting session
  detach/reattach across separate terminal connections while the machine stays running.
- **FR-007**: The laptop MUST support VS Code's remote development tooling connecting as
  `dmiller` over the existing SSH access, providing a working remote session (file access,
  integrated terminal, edit-and-save) with no manual per-connection setup on the laptop.
- **FR-008**: This feature MUST NOT weaken or bypass the SSH security posture established in
  specs/002-harden-ssh-access (key-based authentication only, no root login, no password
  authentication); VS Code Server access MUST operate within those existing constraints per
  Constitution Principle VI.
- **FR-009**: All tooling introduced by this feature MUST be expressed declaratively (Nix
  packages/modules) per Constitution Principle I; no tool may depend on a hand-run install or
  configuration script to function correctly after a rebuild.
- **FR-010**: Per-user environment configuration (shell, zsh plugins, editor, multiplexer)
  MUST be organized as modules distinct from system-wide package installs, consistent with
  Constitution Principle III, so they can be applied to `dmiller` on a future second host
  without duplication.
- **FR-011**: The resulting configuration MUST successfully evaluate and dry-build for the
  laptop host before this feature is considered complete, per Constitution Principle IV.

### Key Entities

- **Development Toolchain**: A named language/platform tool stack (.NET, Go, AWS CLI,
  Terraform, Docker, Kubernetes tooling, Node.js, Python) declared as packages available to
  `dmiller`; each toolchain is independent of the others.
- **Shell Environment**: The `dmiller` user's interactive shell configuration — zsh itself,
  its fuzzy-search integration, its prompt/color theming, its plugin set, and its Git/GitHub
  tooling (`gh`, `ghstack`) — governing day-to-day terminal use.
- **Editor & Session Tooling**: Neovim and tmux, the editing and terminal-session-management
  tools available to `dmiller`.
- **Remote Development Session**: A connection from an external VS Code client to the laptop,
  established over the existing hardened SSH access, that provisions a server-side process
  enabling remote file access, an integrated terminal, and editing.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After a fresh rebuild, a new interactive shell for `dmiller` starts in zsh with
  fuzzy search and all configured plugins active, with zero manual setup steps.
- **SC-002**: A developer can start working in a project requiring any one of C#/.NET, Go,
  AWS CLI, Terraform, Docker, Kubernetes (`kubectl`/`k3d`), Node.js, or Python within the
  same session immediately after a rebuild, without installing anything by hand.
- **SC-003**: A developer can connect to the laptop from VS Code's remote development feature
  and get a fully working remote session (browse files, open a terminal, edit and save) on
  the first attempt.
- **SC-004**: A developer can detach a tmux session, fully disconnect, reconnect later, and
  reattach to find their terminal state (running processes, scrollback) preserved, 100% of
  the time while the machine has stayed running.
- **SC-005**: Reproducing this entire environment on a clean rebuild of the laptop host
  requires zero manual, undeclared installation or configuration steps.

## Assumptions

- This feature applies to the `dmiller` user on the existing `laptop` host only; extending it
  to a second host is deferred until that host exists (Constitution Principle V).
- "Beneficial plugins" for zsh means a small, curated set covering fuzzy history/file search,
  command autosuggestions, syntax highlighting, and improved completion — not an open-ended
  or exhaustive plugin list.
- Per-user configuration (shell, zsh plugins, editor, multiplexer) is expressed via
  home-manager. If home-manager is not already part of this repo, it is added as a pinned
  flake input (Constitution Principle II) as part of this feature — this is the deferred
  per-user environment work called out in FR-006 of
  `specs/001-initial-environment-setup/spec.md`.
- Each toolchain (.NET, Go, Node.js, Python, Terraform, AWS CLI) uses the current stable/LTS
  version available from the pinned `nixpkgs` input; per-project version switching (e.g.,
  nvm-style multi-version tooling) is out of scope.
- "C#/.NET tooling" is interpreted as the SDK plus the ASP.NET Core runtime, the EF Core CLI
  (`dotnet ef`), and one formatter (`csharpier`) — the concrete set the developer confirmed
  during implementation — rather than every possible .NET workload or global tool.
- "AWS tooling" is interpreted as the AWS CLI (`awscli2`) plus the `aws-sso-cli` utility
  (https://github.com/synfinatic/aws-sso-cli) the developer specifically requested for
  AWS SSO-based credential management, rather than every AWS-adjacent CLI that exists.
- Docker is provided in its standard rootful, daemon-based mode; rootless Docker is not
  required.
- "Kubernetes tooling" is interpreted as `kubectl` (the standard Kubernetes CLI) plus `k3d`
  (a tool for running local Kubernetes clusters using the Docker toolchain already provided
  by this feature); no cluster-management service (e.g., a persistent `k3s`/`k0s` install) is
  provisioned — clusters are created on demand, per-developer, via `k3d`.
- The zsh "beneficial plugins" set is extended, per the developer's explicit requests during
  implementation, to include: the GitHub CLI (`gh`) with its zsh completions, `ghstack`
  (Meta's stacked-pull-request tool for GitHub) as a plain installed CLI (no dedicated
  home-manager module needed), a colored git-aware prompt via Starship (chosen for its
  first-class home-manager module and because it inherently satisfies "show which branch I'm
  on"), and colorized `ls`/`grep`/`diff` output via shell aliases — still a curated,
  intentional set rather than an open-ended one.
- "Support for VS Code Server" means the machine can serve VS Code's official remote
  development tooling (Remote-SSH) over the SSH access already hardened in
  specs/002-harden-ssh-access; it does not introduce any additional network-exposed service
  beyond SSH.
- No changes to SSH configuration itself (covered by specs/002-harden-ssh-access) are in
  scope here, beyond whatever is strictly needed for VS Code Server to function within those
  existing constraints.
