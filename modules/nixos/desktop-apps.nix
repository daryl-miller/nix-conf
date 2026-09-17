{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    google-chrome
    obsidian
    bitwarden-desktop
    gitkraken
  ];

  programs.steam.enable = true;
}
