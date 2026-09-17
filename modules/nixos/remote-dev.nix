{ ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
    };
  };

  programs.nix-ld.enable = true;
}
