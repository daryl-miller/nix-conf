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
  ];
}
