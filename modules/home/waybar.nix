{ hyprTheme, ... }:

{
  # Backs the "mpris" waybar module above with MPRIS media-key/state aggregation.
  services.playerctld.enable = true;

  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "mpris"
          "cpu"
          "memory"
          "temperature"
          "network"
          "pulseaudio"
          "battery"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
        };

        clock = {
          format = "{:%H:%M  %a %d %b}";
          tooltip-format = "{:%Y-%m-%d %H:%M}";
        };

        network = {
          format-wifi = "  {essid}";
          format-ethernet = "  {ifname}";
          format-disconnected = "󰤭  disconnected";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
        };

        pulseaudio = {
          format = "{icon}  {volume}%";
          format-muted = "  muted";
          format-icons = {
            default = [ "" "" "" ];
          };
          on-click = "pavucontrol";
        };

        battery = {
          format = "{icon}  {capacity}%";
          format-icons = [ "" "" "" "" "" ];
          format-charging = "  {capacity}%";
          states = {
            warning = 30;
            critical = 15;
          };
        };

        mpris = {
          format = "{player_icon}  {title} - {artist}";
          player-icons = {
            default = "";
            spotify = "";
          };
        };

        cpu = {
          format = "  {usage}%";
        };

        memory = {
          format = "  {percentage}%";
        };

        temperature = {
          thermal-zone = 10;
          format = "{icon}  {temperatureC}°C";
          format-icons = [ "" "" "" ];
          critical-threshold = 90;
        };

        tray = {
          icon-size = 16;
          spacing = 8;
        };
      };
    };

    style = ''
      * {
        font-family: "${hyprTheme.font}";
        font-size: ${toString hyprTheme.fontSize}px;
      }

      window#waybar {
        background-color: #${hyprTheme.colors.base};
        color: #${hyprTheme.colors.text};
        border-bottom: 2px solid #${hyprTheme.colors.surface0};
      }

      #workspaces button {
        padding: 0 8px;
        color: #${hyprTheme.colors.subtext0};
      }

      #workspaces button.active {
        color: #${hyprTheme.colors.mauve};
      }

      #clock,
      #network,
      #pulseaudio,
      #battery,
      #tray,
      #cpu,
      #memory,
      #temperature,
      #mpris {
        padding: 0 10px;
        color: #${hyprTheme.colors.text};
      }

      #battery.warning {
        color: #${hyprTheme.colors.yellow};
      }

      #battery.critical {
        color: #${hyprTheme.colors.red};
      }
    '';
  };
}
