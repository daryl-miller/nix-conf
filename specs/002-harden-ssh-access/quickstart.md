# Quickstart: Validating Harden SSH Access

Run these on the laptop. **Do this in order — do not skip straight to step 3.**

## Prerequisites

- The laptop's configuration already builds and is active (feature 001 complete).
- You have a second terminal/session available (or SSH access from another device) so you
  don't rely on the same session you're editing from to prove the change works.

## Step 1: Declare the key, build, activate — password auth still on

After adding `users.users.dmiller.openssh.authorizedKeys.keys` to
`modules/nixos/users.nix` (no changes to `remote-dev.nix` yet):

```sh
nix flake check
sudo nixos-rebuild dry-activate --flake .#laptop   # review the plan
sudo nixos-rebuild switch --flake .#laptop         # apply it
```

**Expected**: succeeds; `PasswordAuthentication` is still `true` at this point.

## Step 2: Confirm key-based login works (FR-004 gate)

From a separate session/device:

```sh
ssh -i ~/.ssh/id_ed25519 -o PasswordAuthentication=no -o PreferredAuthentications=publickey dmiller@localhost
```

(Substitute the laptop's actual address if testing from another machine.)

**Expected**: login succeeds with no password prompt. **Do not proceed to Step 3 until this
succeeds.** If it fails, fix the declared key in `users.nix` and repeat Step 1 before
continuing — password authentication is still available as a fallback at this point.

## Step 3: Disable password authentication and root login

After Step 2 has succeeded, update `modules/nixos/remote-dev.nix`
(`PasswordAuthentication = false;`, `PermitRootLogin = "no";`):

```sh
nix flake check
sudo nixos-rebuild dry-activate --flake .#laptop
sudo nixos-rebuild switch --flake .#laptop
```

## Step 4: Confirm both success criteria

```sh
# SC-002: key login still works
ssh -i ~/.ssh/id_ed25519 dmiller@localhost -o PreferredAuthentications=publickey echo ok

# SC-001: password-only login is now rejected
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no dmiller@localhost echo should-not-succeed
# expect: "Permission denied (publickey)" or connection refused — NOT a password prompt

# FR-003: root login is rejected regardless of method
ssh root@localhost echo should-not-succeed
# expect: "Permission denied" — no password prompt, no key accepted
```

## Step 5: Confirm local login is unaffected (SC-004)

Log out and back in at the laptop's own screen (KDE/SDDM) as `dmiller` using the normal
account password. This path does not go through `sshd` and must be completely unaffected.

## Step 6: Confirm reproducibility (SC-003)

```sh
grep -A3 "authorizedKeys" modules/nixos/users.nix
```

Confirm the key is present in the Nix source itself (not only in the machine's
`~/.ssh/authorized_keys`), so a from-scratch rebuild would reproduce it.
