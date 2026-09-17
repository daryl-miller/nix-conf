# Home-manager concern modules

Each file here owns one category of per-user settings and is host-agnostic — it contains
nothing specific to a particular machine or user identity, so any Home Configuration
(`modules/home/<user>.nix`) can import the ones it needs.

| Module | Settings owned |
|---|---|
| `shell.nix` | `programs.zsh.enable`, `programs.zsh.autosuggestion.enable`, `programs.zsh.syntaxHighlighting.enable`, `programs.zsh.enableCompletion`, `programs.zsh.shellAliases` (colored `ls`/`grep`/`diff`), `programs.fzf.enable`, `programs.fzf.enableZshIntegration`, `programs.starship.enable`, `programs.starship.enableZshIntegration` |
| `editor.nix` | `programs.neovim.enable` |
| `tmux.nix` | `programs.tmux.enable` |
| `github.nix` | `programs.gh.enable`, `home.packages` (`ghstack`) |

User-identity settings (`home.username`, `home.homeDirectory`, `home.stateVersion`) and the
list of which concern modules apply never live here — they stay in each user's own
`modules/home/<user>.nix` (currently just `dmiller.nix`), which is wired into the system via
`modules/nixos/home-manager.nix`.
