{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/nixos/locale.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/printing.nix
    ../../modules/nixos/nix-settings.nix
    ../../modules/nixos/dev-tools.nix
    ../../modules/nixos/remote-dev.nix
    ../../modules/nixos/home-manager.nix
  ];

  # See: https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "26.05";
}
