# Quickstart: Validating Developer Environment Tooling

Run these on the laptop itself (this is the machine the configuration describes).

## Prerequisites

- A clean checkout of this repository with `flake.nix` (+ `home-manager` input),
  `modules/nixos/`, and `modules/home/` updated per `plan.md`.
- Network access for the initial `nix flake check`/build, so the new `home-manager` flake
  input can be fetched and locked.

## 1. Evaluate the flake

```sh
nix flake check
```

**Expected**: exits 0 — the flake, the `laptop` NixOS configuration, and the
`home-manager.users.dmiller` activation all evaluate without error. This is the
Constitution Principle II check, and confirms `flake.lock` now also pins `home-manager`.

## 2. Dry-build the laptop configuration

```sh
sudo nixos-rebuild dry-activate --flake .#laptop
```

**Expected**: succeeds; the activation plan includes the new packages (`dotnet-sdk`,
`awscli2`, `terraform`, `docker`, `nodejs`, `python3`, `neovim`, `tmux`, `fzf`, zsh
plugins) and the home-manager generation for `dmiller`. This is the FR-011 gate; nothing in
this feature is done until this passes. Then actually apply it:

```sh
sudo nixos-rebuild switch --flake .#laptop
```

## 3. Toolchains on `PATH` with no manual install (User Story 1 / SC-002)

Open a **new** shell (so group membership and `PATH` changes take effect) and run:

```sh
dotnet --version      # .NET SDK
aws --version         # AWS CLI
terraform -version
docker run --rm hello-world   # confirms daemon is running AND dmiller needs no sudo (FR-002)
node --version
python3 --version
```

**Expected**: every command succeeds with no `sudo`, no "command not found", and no prompt
to install anything further.

## 4. zsh with fuzzy search and plugins (User Story 2 / SC-001)

```sh
echo $SHELL            # expect a path ending in /zsh
```

In the interactive zsh session:
- Press **Ctrl-R**: expect an `fzf` fuzzy history-search interface to appear.
- Press **Ctrl-T**: expect an `fzf` fuzzy file-search interface to appear.
- Start typing a command you've run before: expect a greyed-out autosuggestion to appear
  inline.
- Type a valid vs. invalid command: expect syntax highlighting to visibly differ (e.g.
  green vs. red) as you type.

## 5. Neovim and tmux (User Story 3 / SC-004)

```sh
nvim /tmp/quickstart-test.txt   # edit, save (:wq), confirm the file was written
```

```sh
tmux new -s qs
# inside tmux: start a long-running process, e.g. `sleep 600 &`
# detach: Ctrl-b then d
exit   # close the terminal / SSH session entirely
```

Reconnect (new terminal or new SSH session) and run:

```sh
tmux attach -t qs
```

**Expected**: the session reattaches with the `sleep` process (or equivalent) still running
and prior scrollback intact.

## 6. VS Code remote development (User Story 4 / SC-003)

From a **separate machine** with VS Code and the Remote-SSH extension installed, already
holding an authorized SSH key per `specs/002-harden-ssh-access`:

1. Connect to the laptop as `dmiller` via VS Code's "Connect to Host..." (Remote-SSH).
2. **Expected**: the remote server bootstraps successfully (no `nix-ld`/dynamic-linker
   errors in the Remote-SSH output log), the file explorer shows the laptop's filesystem, and
   an integrated terminal opens.
3. Edit and save a file from the remote VS Code window; **expected**: the change appears in
   the file on the laptop (verify with `cat`/`stat` over a normal SSH session).
4. Confirm no new behavior was needed beyond the existing hardened SSH login — i.e., the
   connection fails exactly like a normal SSH login would if the client's key isn't
   authorized (FR-008 / no weaker path introduced).

## 7. Zero manual steps end-to-end (SC-005)

Starting from a clean checkout on a machine that can already build this flake, confirm every
step above (2–6) succeeds having only run `nixos-rebuild switch` once — no additional
imperative `apt`/`dnf`/manual download/config-file-editing step was required anywhere in
steps 3–6.
