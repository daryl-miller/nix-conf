{ ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      diff = "diff --color=auto";
      nrs = "sudo nixos-rebuild switch --flake /home/dmiller/repos/nix-config#laptop";
      repos = "cd /home/dmiller/repos";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
