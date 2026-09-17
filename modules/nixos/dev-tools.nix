{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    claude-code
    vscode
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
  ];

  virtualisation.docker.enable = true;
}
