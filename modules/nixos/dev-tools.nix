{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    claude-code
  ];
}
