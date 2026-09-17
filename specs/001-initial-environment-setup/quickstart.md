# Quickstart: Validating Initial Minimum Environment Setup

Run these on the laptop itself (this is the machine the configuration describes).

## Prerequisites

- Nix with flakes enabled (already true, since this machine runs NixOS).
- A clean checkout of this repository with the `flake.nix`, `hosts/laptop/`, and
  `modules/nixos/` structure from `plan.md` in place.

## 1. Evaluate the flake

```sh
nix flake check
```

**Expected**: exits 0 — the flake and the `laptop` NixOS configuration evaluate without
error. This is the FR-002 / Constitution Principle II check.

## 2. Dry-build the laptop configuration

```sh
sudo nixos-rebuild dry-activate --flake .#laptop
```

(or `nixos-rebuild build --flake .#laptop` if you only want the derivation built, not a
dry-activation plan).

**Expected**: succeeds and the activation plan shows no unexpected removals/changes beyond
what this feature intentionally touches (file reorganization only — no behavioral diff for
carried-over settings). This is the FR-009 gate; nothing in this feature is done until this
passes.

## 3. Confirm carried-over settings match the running system (SC-002)

Spot-check the settings listed in FR-004 against the built configuration, e.g.:

```sh
# locale
localectl status | grep "System Locale"          # expect en_AU.UTF-8
timedatectl show -p Timezone                      # expect Australia/Melbourne

# desktop / display manager
systemctl status sddm                             # expect active, from services.displayManager.sddm

# networking
systemctl status NetworkManager                   # expect active

# audio
systemctl --user status pipewire                  # expect active; pulseaudio.service should not exist

# printing
systemctl status cups                             # expect active

# ssh (relocated to modules/nixos/remote-dev.nix per research.md Decision 3)
systemctl status sshd
grep -i PasswordAuthentication /etc/ssh/sshd_config  # expect "yes" (still enabled, per FR-008)

# dev tools (FR-011 / SC-005)
git --version
claude --version
```

All of the above should reflect the same effective state before and after switching to the
repo's configuration — this feature reorganizes and fixes the source, it does not change
runtime behavior (with the sole intentional fix being removal of the injected `fetchTarball`
import, which had no runtime effect to begin with).

## 4. Confirm `hardware-configuration.nix` is clean (SC-004)

```sh
sudo nixos-generate-config --show-hardware-config > /tmp/fresh-hw-config.nix
diff /tmp/fresh-hw-config.nix hosts/laptop/hardware-configuration.nix
```

**Expected**: no diff (or only inconsequential whitespace/comment differences from the
generator). In particular, confirm:
- No `fetchTarball` (or any other network-fetch) call anywhere in the file.
- No `services.openssh` or `services.nixos-vscode-server` blocks (those now live in
  `modules/nixos/remote-dev.nix`).

## 5. Confirm module discoverability (SC-003)

Without searching file contents, locate the file responsible for each of: locale, boot,
networking, desktop, users, audio, printing, and Nix daemon settings, using only
`modules/nixos/` filenames. Each should be found in well under 30 seconds.
