{ pkgs, ... }:

{
  programs.gh.enable = true;

  home.packages = with pkgs; [
    ghstack
  ];
}
