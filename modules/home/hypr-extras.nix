{ pkgs, ... }:

{
  # --- Clipboard history, screen recording, color picker (spec FR-009) ---
  services.cliphist.enable = true;

  home.packages = [
    pkgs.wf-recorder
    pkgs.hyprpicker
  ];

  wayland.windowManager.hyprland.settings.bind = [
    "$mainMod, V, exec, cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"
    "$mainMod, R, exec, pkill -SIGINT wf-recorder || wf-recorder -f $HOME/recording-$(date +%Y%m%d-%H%M%S).mp4"
    "$mainMod, P, exec, hyprpicker -a"
  ];

  # --- Bluetooth / network tray applets (spec FR-009) ---
  services.blueman-applet.enable = true;
  services.network-manager-applet.enable = true;
}
