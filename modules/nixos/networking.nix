{ ... }:

{
  # Hostname is intentionally left as the current "nixos" default for this feature;
  # renaming is deferred until a second host makes distinct identifiers necessary.
  networking.hostName = "nixos";

  networking.networkmanager.enable = true;

  services.tailscale.enable = true;
}
