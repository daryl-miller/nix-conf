# Quickstart: Validate Chrome, Obsidian & Bitwarden Desktop Apps

This guide validates the feature end-to-end once implemented, per Constitution Principle
IV (Build & Validate Before Merge) and the acceptance scenarios in `spec.md`.

## Prerequisites

- Changes to `modules/nixos/desktop-apps.nix` and `hosts/laptop/configuration.nix` are in
  place (see `plan.md` Project Structure).
- Run from the repository root.

## 1. Evaluate and dry-build (required before considering the feature done)

```sh
nix flake check
nixos-rebuild dry-activate --flake .#laptop
```

Expected outcome: both commands complete without error. `dry-activate` should list the
three new packages (`google-chrome`, `obsidian`, `bitwarden-desktop`) as being added to
the system profile.

## 2. Apply the change

```sh
sudo nixos-rebuild switch --flake .#laptop
```

Expected outcome: the rebuild succeeds and the running system now has the three
applications installed.

## 3. Validate User Story 1 — Chrome (P1)

1. From either desktop session (Plasma6 or Hyprland), launch Chrome from the application
   launcher.
2. Confirm it opens and loads a web page.
3. Close and relaunch Chrome; confirm previously set state (e.g., a bookmark) persisted.
4. Confirm Firefox still launches and works normally (spec FR-005 / Edge Cases).

Expected outcome: matches spec.md User Story 1 Acceptance Scenarios 1–2.

## 4. Validate User Story 2 — Obsidian (P2)

1. Launch Obsidian from the application launcher.
2. Create a new vault (or open an existing one) and create a note.
3. Close and reopen Obsidian; confirm the note exists on disk as a Markdown file.

Expected outcome: matches spec.md User Story 2 Acceptance Scenarios 1–2.

## 5. Validate User Story 3 — Bitwarden (P3)

1. Launch the Bitwarden desktop app from the application launcher.
2. Confirm a login screen is presented.
3. Log in with an existing Bitwarden account and confirm vault items are visible.

Expected outcome: matches spec.md User Story 3 Acceptance Scenarios 1–2.

## 6. Validate persistence (FR-004)

1. After using each app at least once (steps 3–5 above), reboot the laptop (or at minimum
   re-run `nixos-rebuild switch --flake .#laptop` with no further changes).
2. Relaunch each application and confirm prior state (Chrome bookmark, Obsidian note,
   Bitwarden logged-in session or saved email) is still present.

Expected outcome: matches spec.md Success Criteria SC-001–SC-003 and the Edge Cases
regarding data persistence across rebuilds.
