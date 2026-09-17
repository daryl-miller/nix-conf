# Home-manager concern modules

Each file here owns one category of per-user settings and is host-agnostic — it contains
nothing specific to a particular machine or user identity, so any Home Configuration
(`modules/home/<user>.nix`) can import the ones it needs.

| Module | Settings owned |
|---|---|
| `shell.nix` | `programs.zsh.enable`, `programs.zsh.autosuggestion.enable`, `programs.zsh.syntaxHighlighting.enable`, `programs.zsh.enableCompletion`, `programs.zsh.shellAliases` (colored `ls`/`grep`/`diff`, `nrs` for rebuild-switch), `programs.fzf.enable`, `programs.fzf.enableZshIntegration`, `programs.starship.enable`, `programs.starship.enableZshIntegration` |
| `editor.nix` | `programs.neovim.enable` |
| `tmux.nix` | `programs.tmux.enable` |
| `github.nix` | `programs.gh.enable`, `home.packages` (`ghstack`) |
| `theme.nix` | `_module.args.hyprTheme` — the shared Catppuccin Mocha palette/font/corner-radius/animation-curve attrset consumed by the Hyprland-session modules below |
| `hyprland.nix` | `wayland.windowManager.hyprland.{enable,plugins,settings}` — core compositor config: keybindings, monitors, animations, window rules, and the `hy3` / `borders-plus-plus` plugins. Hyprland's config syntax changes between versions (options get renamed or removed), so any edit here should be re-validated with `nix flake check`, which runs the generated `hyprland.conf` through `Hyprland --verify-config` via the `checks.hyprland-config` output in `flake.nix` — this catches config errors headlessly, without needing to log into the session. |
| `waybar.nix` | `programs.waybar.{enable,systemd.enable,settings,style}`, `services.playerctld.enable` |
| `hypr-shell.nix` | `programs.kitty.*`, `programs.fuzzel.*`, `services.awww.enable`, `services.mako.*`, `programs.hyprlock.*`, `services.hypridle.*` — the Hyprland session's "sane defaults" baseline (terminal, launcher, wallpaper, notifications, lock/idle, screenshot) |
| `hypr-extras.nix` | `services.cliphist.enable`, `services.blueman-applet.enable`, `services.network-manager-applet.enable`, `home.packages` (`wf-recorder`, `hyprpicker`) — the Hyprland session's optional nice-to-have tools |

User-identity settings (`home.username`, `home.homeDirectory`, `home.stateVersion`) and the
list of which concern modules apply never live here — they stay in each user's own
`modules/home/<user>.nix` (currently just `dmiller.nix`), which is wired into the system via
`modules/nixos/home-manager.nix`.
