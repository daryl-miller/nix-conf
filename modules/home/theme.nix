{ ... }:

{
  # Catppuccin Mocha palette, shared by every Hyprland-session module (hyprland.nix,
  # waybar.nix, hypr-shell.nix) so the whole session stays visually consistent from one
  # source of truth. See specs/004-hyprland-desktop/research.md #10.
  _module.args.hyprTheme = {
    colors = {
      base = "1e1e2e";
      mantle = "181825";
      crust = "11111b";
      text = "cdd6f4";
      subtext0 = "a6adc8";
      surface0 = "313244";
      surface1 = "45475a";
      overlay0 = "6c7086";
      blue = "89b4fa";
      lavender = "b4befe";
      mauve = "cba6f7";
      red = "f38ba8";
      green = "a6e3a1";
      yellow = "f9e2af";
      peach = "fab387";
    };

    font = "JetBrainsMono Nerd Font";
    fontSize = 11;

    cornerRadius = 10;
    animationCurve = "easeOutQuint,0.23,1,0.32,1";
  };
}
