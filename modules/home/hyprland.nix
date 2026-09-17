{ pkgs, hyprTheme, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;

    # Pin the classic hyprlang (.conf) format rather than home-manager's newer default
    # ("lua" for stateVersion >= 26.05): its generator emits `hl.${key}(...)` verbatim for
    # every settings key, which is invalid Lua for any key containing a hyphen (e.g.
    # "exec-once", "borders-plus-plus", both used below) — hyprlang has no such issue and
    # is the long-established, unambiguous format this config relies on working unmodified.
    configType = "hyprlang";

    # Extra plugins (spec FR-009): hy3 (i3-style alternate tiling layout) and
    # borders-plus-plus (animated multi-borders). hyprspace was tried first but fails to
    # compile against this pinned nixpkgs' Hyprland version; hy3 is additionally a closer
    # match to the originally-approved "alternate tiling layout" option (research.md #9).
    plugins = [
      pkgs.hyprlandPlugins.hy3
      pkgs.hyprlandPlugins.borders-plus-plus
    ];

    settings = {
      # AQ_NO_MODIFIERS forces linear (uncompressed) DRM buffers instead of the default
      # Y_TILED_CCS modifier. Without it, aquamarine's atomic test-commit fails with
      # "Invalid argument" for eDP-1 and DP-2 on this WhiskeyLake-U iGPU whenever all three
      # outputs (4K internal panel + 2 external monitors) are active together, leaving those
      # two stuck at an invalid 0x0 mode while only the third (DP-4) comes up. DP-4 already
      # happens to land on plain Y_TILED and was unaffected.
      env = [ "AQ_NO_MODIFIERS,1" ];

      monitor = [
        # Acer XB271HU is enumerated as DP-4 (not HDMI-A-1 despite the HDMI cable — this
        # iGPU/dock reports it as a DisplayPort connector), portrait rotated 90° clockwise
        "DP-4,preferred,auto,1,transform,1"
        ",preferred,auto,auto"
      ];

      "$mainMod" = "SUPER";
      "$terminal" = "kitty";
      "$launcher" = "fuzzel";

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" =
          "rgba(${hyprTheme.colors.mauve}ff) rgba(${hyprTheme.colors.blue}ff) 45deg";
        "col.inactive_border" = "rgba(${hyprTheme.colors.overlay0}aa)";
        layout = "dwindle";
      };

      decoration = {
        rounding = hyprTheme.cornerRadius;
        blur = {
          enabled = true;
          size = 4;
          passes = 2;
        };
      };

      animations = {
        enabled = true;
        bezier = [ hyprTheme.animationCurve ];
        animation = [
          "windows, 1, 4, easeOutQuint"
          "windowsOut, 1, 4, easeOutQuint, popin 80%"
          "border, 1, 8, easeOutQuint"
          "fade, 1, 4, easeOutQuint"
          "workspaces, 1, 5, easeOutQuint, slide"
        ];
      };

      dwindle = {
        # `pseudotile` was removed entirely in this pinned Hyprland version (0.56.2) — no
        # replacement option exists, it's just gone, so it's dropped here rather than
        # migrated.
        preserve_split = true;
      };

      plugin."borders-plus-plus" = {
        add_borders = 1;
        natural_rounding = true;
        "col.border_1" = "rgba(${hyprTheme.colors.lavender}ff)";
        border_size_1 = 2;
      };

      # `windowrulev2` is deprecated in this pinned Hyprland version in favor of
      # `windowrule`'s new v3 syntax: comma-separated fields, each either
      # "<effect> <value>" or "match:<prop> <value>" (space-separated, not colon-attached
      # like v2's "class:<regex>"). The effect itself was also renamed: "suppressevent" ->
      # "suppress_event" (verified against Hyprland's own WindowRuleEffectContainer.cpp
      # effect-string table).
      windowrule = [
        "suppress_event maximize, match:class .*"
      ];

      # Core window-management bindings (spec FR-002; contracts/keybindings.md)
      bind = [
        "$mainMod, Return, exec, $terminal"
        "$mainMod, Space, exec, $launcher"
        "$mainMod, Q, killactive,"
        "$mainMod, L, exec, hyprlock"
        "$mainMod, T, exec, hyprctl keyword general:layout $(hyprctl getoption general:layout | awk '/str:/{print ($2==\"hy3\")?\"dwindle\":\"hy3\"}')"

        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, down, movewindow, d"

        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"
      ];

      binde = [
        "$mainMod CTRL, right, resizeactive, 20 0"
        "$mainMod CTRL, left, resizeactive, -20 0"
        "$mainMod CTRL, up, resizeactive, 0 -20"
        "$mainMod CTRL, down, resizeactive, 0 20"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };
}
