{ pkgs, ... }:

{
  users.users."dmiller" = {
    isNormalUser = true;
    description = "dmiller";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINiQi43ehLNCXZN+Uxxn+Rt6PnXOy5iHiy/osYe6rjpn micro@krux-desktop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPa4vo9/0MdRuvVakFKou5gsLRvaxsR/aerEvulZBT+S dmiller@nixos"
    ];
  };

  programs.firefox.enable = true;
}
