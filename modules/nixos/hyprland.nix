{ ... }:

{
  # Registers a Hyprland session in the display manager and wires its XDG desktop portal
  # (xdg-desktop-portal-hyprland) automatically; no manual xdg.portal config needed here.
  programs.hyprland.enable = true;

  # Backs home-manager's services.blueman-applet (modules/home/hypr-extras.nix), which
  # requires the system-wide blueman service to be running.
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}
