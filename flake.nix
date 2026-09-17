{
  description = "Daryl Miller's NixOS system configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/laptop/configuration.nix
          home-manager.nixosModules.home-manager
        ];
      };

      checks.${system}.hyprland-config =
        let
          cfg = self.nixosConfigurations.laptop.config;
          pkgs = self.nixosConfigurations.laptop.pkgs;
          # Hyprland's own `--verify-config` parses a config file and reports errors
          # without starting a Wayland session, so this catches config-syntax mistakes
          # (e.g. a keyword renamed/removed between Hyprland versions) at `nix flake
          # check` time instead of only at login.
          configFile =
            cfg.home-manager.users.dmiller.home.file."/home/dmiller/.config/hypr/hyprland.conf".source;
        in
        pkgs.runCommand "hyprland-config-check" { } ''
          HOME=$TMPDIR XDG_RUNTIME_DIR=$TMPDIR ${pkgs.hyprland}/bin/Hyprland --config ${configFile} --verify-config
          touch $out
        '';
    };
}
