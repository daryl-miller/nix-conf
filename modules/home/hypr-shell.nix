{ pkgs, hyprTheme, ... }:

let
  wallpaper = pkgs.runCommand "hyprland-wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick -size 1920x1080 xc:"#${hyprTheme.colors.base}" "$out"
  '';
in
{
  # --- Terminal (spec FR-002 "open terminal") ---
  programs.kitty = {
    enable = true;
    font = {
      name = hyprTheme.font;
      size = hyprTheme.fontSize + 1.0;
    };
    settings = {
      background = "#${hyprTheme.colors.base}";
      foreground = "#${hyprTheme.colors.text}";
      cursor = "#${hyprTheme.colors.text}";
      selection_background = "#${hyprTheme.colors.surface1}";
      selection_foreground = "#${hyprTheme.colors.text}";

      active_border_color = "#${hyprTheme.colors.lavender}";
      inactive_border_color = "#${hyprTheme.colors.overlay0}";

      color0 = "#${hyprTheme.colors.surface0}";
      color8 = "#${hyprTheme.colors.overlay0}";
      color1 = "#${hyprTheme.colors.red}";
      color9 = "#${hyprTheme.colors.red}";
      color2 = "#${hyprTheme.colors.green}";
      color10 = "#${hyprTheme.colors.green}";
      color3 = "#${hyprTheme.colors.yellow}";
      color11 = "#${hyprTheme.colors.yellow}";
      color4 = "#${hyprTheme.colors.blue}";
      color12 = "#${hyprTheme.colors.blue}";
      color5 = "#${hyprTheme.colors.mauve}";
      color13 = "#${hyprTheme.colors.mauve}";
      color6 = "#94e2d5";
      color14 = "#94e2d5";
      color7 = "#${hyprTheme.colors.subtext0}";
      color15 = "#${hyprTheme.colors.text}";

      confirm_os_window_close = 0;
    };
  };

  # --- Application launcher (spec FR-004) ---
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "${hyprTheme.font}:size=${toString hyprTheme.fontSize}";
        terminal = "kitty";
      };
      colors = {
        background = "${hyprTheme.colors.base}ee";
        text = "${hyprTheme.colors.text}ff";
        match = "${hyprTheme.colors.blue}ff";
        selection = "${hyprTheme.colors.surface1}ff";
        selection-match = "${hyprTheme.colors.blue}ff";
        selection-text = "${hyprTheme.colors.text}ff";
        border = "${hyprTheme.colors.lavender}ff";
      };
      border = {
        width = 2;
        radius = hyprTheme.cornerRadius;
      };
    };
  };

  # --- Wallpaper (spec FR-006) ---
  services.awww.enable = true;

  wayland.windowManager.hyprland.settings.exec-once = [
    "awww img ${wallpaper} --transition-type fade --transition-fps 60"
  ];

  # --- Notifications (spec FR-008) ---
  services.mako = {
    enable = true;
    settings = {
      background-color = "#${hyprTheme.colors.surface0}ee";
      text-color = "#${hyprTheme.colors.text}";
      border-color = "#${hyprTheme.colors.lavender}";
      border-radius = hyprTheme.cornerRadius;
      border-size = 2;
      font = "${hyprTheme.font} ${toString hyprTheme.fontSize}";
      default-timeout = 6000;
      layer = "overlay";
      anchor = "top-right";
      margin = "10";
    };
  };

  # --- Screen lock (spec FR-005) ---
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      background = [
        {
          path = "${wallpaper}";
          blur_passes = 2;
          blur_size = 6;
        }
      ];

      input-field = [
        {
          size = "250, 60";
          position = "0, -60";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          outer_color = "rgba(${hyprTheme.colors.lavender}ff)";
          inner_color = "rgba(${hyprTheme.colors.surface0}ee)";
          font_color = "rgba(${hyprTheme.colors.text}ff)";
          placeholder_text = "Password...";
          outline_thickness = 3;
        }
      ];

      label = [
        {
          text = "cmd[update:1000] echo \"$(date +'%H:%M')\"";
          position = "0, 100";
          halign = "center";
          valign = "center";
          font_size = 64;
          color = "rgba(${hyprTheme.colors.text}ff)";
        }
      ];
    };
  };

  # --- Idle behavior: auto-lock + DPMS off (spec FR-005) ---
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "hyprlock";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "hyprlock";
        }
        {
          timeout = 360;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  # --- Screenshots (spec FR-007) + Logout / power menu ---
  home.packages = [ pkgs.grimblast pkgs.wlogout ];

  wayland.windowManager.hyprland.settings.bind = [
    ", Print, exec, grimblast copy screen"
    "SHIFT, Print, exec, grimblast copy area"

    # GUI menu (lock/logout/suspend/hibernate/shutdown/reboot) using the package's default layout
    "$mainMod SHIFT, E, exec, wlogout"
    # Immediate session exit, no confirmation
    "$mainMod SHIFT, Q, exec, hyprctl dispatch exit"
  ];
}
