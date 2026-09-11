# Phase 1 Data Model: Initial Minimum Environment Setup

This feature has no application data; the "entities" below are the configuration units
introduced by this repo's structure (see spec.md Key Entities). They exist to make module
boundaries and ownership unambiguous during implementation and future changes.

## Host Configuration

Represents the complete NixOS configuration for one physical machine.

| Field | Description |
|---|---|
| `name` | Stable identifier used as the flake output name and `hosts/<name>/` directory (e.g., `laptop`). Independent of the OS-level `networking.hostName` (FR-007 keeps that as `nixos` for now). |
| `hardware-configuration.nix` | Untouched `nixos-generate-config` output for this machine only. Never imported by another host. |
| `configuration.nix` | Host entrypoint: imports its own `hardware-configuration.nix` plus the concern modules it needs from `modules/nixos/`. |

**Instances in this feature**: exactly one — `laptop`.

**Validation rule**: A Host Configuration's `hardware-configuration.nix` MUST contain no
content beyond genuine hardware-scan output (FR-001, SC-004).

## Concern Module

A single-purpose Nix file under `modules/nixos/` owning one category of settings, importable
by any Host Configuration that needs it.

| Field | Description |
|---|---|
| `name` | Filename identifying the concern (e.g., `locale`, `boot`, `networking`, `desktop`, `users`, `audio`, `printing`, `nix-settings`, `remote-dev`). |
| `settings owned` | The specific option paths this module is responsible for (see table below). |
| `hardware-specific?` | No — by construction, anything hardware-specific stays in a Host Configuration's own `hardware-configuration.nix`, not here. |

**Validation rule**: Each setting from FR-004/FR-005 is owned by exactly one Concern Module
— no setting is duplicated across modules or left in a host's `configuration.nix` directly
(FR-003).

### Concern Module → settings mapping (from FR-003, FR-004, FR-005, and Decision 3/5 in research.md)

| Module | Settings owned |
|---|---|
| `locale.nix` | `time.timeZone`, `i18n.defaultLocale`, `i18n.extraLocaleSettings.*` |
| `boot.nix` | `boot.loader.systemd-boot.enable`, `boot.loader.efi.canTouchEfiVariables` |
| `networking.nix` | `networking.networkmanager.enable`, `networking.hostName` |
| `desktop.nix` | `services.xserver.enable`, `services.displayManager.sddm.enable`, `services.desktopManager.plasma6.enable`, `services.xserver.xkb.{layout,variant}` |
| `users.nix` | `users.users.dmiller.*`, `programs.firefox.enable` |
| `audio.nix` | `services.pulseaudio.enable`, `security.rtkit.enable`, `services.pipewire.*` |
| `printing.nix` | `services.printing.enable` |
| `nix-settings.nix` | `nix.settings.*`, `nixpkgs.config.allowUnfree` |
| `remote-dev.nix` | `services.openssh.enable`, `services.openssh.settings.PasswordAuthentication`, `services.nixos-vscode-server.enable` |
| `dev-tools.nix` | `environment.systemPackages` (`git`, `claude-code`) |

`system.stateVersion = "26.05"` stays on the Host Configuration itself (`hosts/laptop/configuration.nix`),
since it is defined as machine/install-specific by NixOS convention (not to be changed
independent of the host that first set it) rather than a shared concern.
