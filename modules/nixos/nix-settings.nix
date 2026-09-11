{ ... }:

{
  nixpkgs.config.allowUnfree = true;

  # The machine's /etc/nix/nix.conf (generated from nix.* options) currently holds only
  # NixOS's stock defaults (allowed-users, sandbox, substituters, trusted-*, etc.) — nothing
  # deviates from default, so there is nothing to declare under `nix.settings` yet. If any
  # of those values are ever customized, they belong here so the daemon config stays
  # reproducible from source (see FR-005).
}
