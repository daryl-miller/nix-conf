# Phase 1 Data Model: Harden SSH Access

No new entities are introduced — this feature adds fields to entities already defined in
feature 001's `data-model.md` (Host Configuration, Concern Module). Only the following
attribute is new.

## Authorized SSH Key (attribute of the existing `users.nix` Concern Module)

Two instances, per research.md Decision 3 (corrected after finding the original single-key
assumption was wrong):

| Field | Key 1 | Key 2 |
|---|---|---|
| `user` | `dmiller` | `dmiller` |
| `value` | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINiQi43ehLNCXZN+Uxxn+Rt6PnXOy5iHiy/osYe6rjpn micro@krux-desktop` | `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPa4vo9/0MdRuvVakFKou5gsLRvaxsR/aerEvulZBT+S dmiller@nixos` |
| provenance | Already present in `~/.ssh/authorized_keys`; proven to currently grant access | Present as this laptop's own keypair (`~/.ssh/id_ed25519.pub`); not previously proven for remote login |
| `owning module` | `modules/nixos/users.nix`, via `users.users.dmiller.openssh.authorizedKeys.keys` | same |

**Validation rule**: The declared key MUST successfully authenticate before
`services.openssh.settings.PasswordAuthentication` is set to `false` (FR-004, research.md
Decision 2) — this is a sequencing rule on *when* the second module change may be made, not
just a property of the key itself.

## Updated settings on the existing `remote-dev.nix` Concern Module

| Setting | Before (feature 001) | After (this feature) |
|---|---|---|
| `services.openssh.settings.PasswordAuthentication` | `true` | `false` (FR-001) |
| `services.openssh.settings.PermitRootLogin` | unset (OpenSSH/NixOS default: `"prohibit-password"`) | `"no"` (FR-003) |
