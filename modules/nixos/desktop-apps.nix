{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    google-chrome
    obsidian
    bitwarden-desktop
    gitkraken
    pavucontrol
    piper
  ];

  programs.steam.enable = true;

  # Lets Piper/ratbagctl configure onboard DPI on gaming mice (e.g. the Logitech G703) —
  # the real way to go faster than Hyprland's software `sensitivity` cap of 1.0.
  services.ratbagd.enable = true;

  # ratbagctl writes DPI/profile settings directly to the mouse's own onboard flash, so
  # they already survive reboots on their own — this unit exists so the *desired* state
  # (G703 on profile 0 / 1600dpi) is reproducible from source rather than living only on
  # the physical device, and self-heals if the mouse is ever reset, re-paired, or swapped.
  # Device names from `ratbagctl list` (e.g. "warbling-mara") are assigned per-daemon-run,
  # not stable across reboots, so this looks the device up by product name each time.
  systemd.services.g703-dpi = {
    description = "Reassert Logitech G703 onboard DPI profile";
    wantedBy = [ "multi-user.target" ];
    after = [ "dbus.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      for i in $(seq 1 10); do
        device=$(${pkgs.libratbag}/bin/ratbagctl list | grep 'G703' | cut -d: -f1)
        if [ -n "$device" ]; then
          ${pkgs.libratbag}/bin/ratbagctl "$device" profile active set 0
          ${pkgs.libratbag}/bin/ratbagctl "$device" profile 0 resolution active set 2
          exit 0
        fi
        sleep 2
      done
      echo "G703 not found after retries" >&2
    '';
  };
}
