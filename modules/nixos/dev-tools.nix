{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    claude-code
    # Opts VS Code's Electron/Chromium shell out of Wayland color management
    # (wp_color_management). Hyprland's HDR sdrbrightness has no effect on
    # color-managed clients — VS Code renders noticeably dimmer than every other app
    # under cm=hdr on DP-2 (modules/home/hyprland.nix) with no way to compensate;
    # this flag is the documented workaround (Hyprland discussions #14999, #12165).
    (vscode.override { commandLineArgs = "--disable-features=WaylandWpColorManagerV1"; })
    dotnet-sdk
    dotnet-aspnetcore
    dotnet-ef
    csharpier
    go
    awscli2
    aws-sso-cli
    terraform
    nodejs
    python3
    kubectl
    k3d
    wlr-randr
    nwg-displays
    usbutils
    btop
    traceroute
    jq
    curl
  ];

  virtualisation.docker.enable = true;
}
