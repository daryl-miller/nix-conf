{ ... }:

{
  home.username = "dmiller";
  home.homeDirectory = "/home/dmiller";
  home.stateVersion = "26.05";

  imports = [
    ./shell.nix
    ./editor.nix
    ./tmux.nix
    ./github.nix
    ./theme.nix
    ./hyprland.nix
    ./waybar.nix
    ./hypr-shell.nix
    ./hypr-extras.nix
    ./wallpapers.nix
  ];
}
