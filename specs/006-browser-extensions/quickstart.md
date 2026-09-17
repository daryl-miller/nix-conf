# Quickstart: Validate Browser Extensions (Chrome & Firefox)

This guide validates the feature end-to-end once implemented, per Constitution Principle
IV (Build & Validate Before Merge) and the acceptance scenarios in `spec.md`.

## Prerequisites

- Changes to `modules/nixos/browser-extensions.nix` and
  `hosts/laptop/configuration.nix` are in place (see `plan.md` Project Structure).
- Run from the repository root.

## 1. Evaluate and dry-build (required before considering the feature done)

```sh
nix flake check
nixos-rebuild dry-build --flake .#laptop
```

Expected outcome: both commands complete without error.

## 2. Apply the change

```sh
sudo nixos-rebuild switch --flake .#laptop
```

Expected outcome: the rebuild succeeds; `/etc/opt/chrome/policies/managed/default.json`
and `/etc/firefox/policies/policies.json` now exist and contain the four extension
entries each.

## 3. Validate User Story 1 — Content blocker (P1)

1. Open Chrome, go to `chrome://extensions`, and confirm "uBlock Origin Lite" is listed
   and enabled.
2. Open Firefox, go to `about:addons`, and confirm "uBlock Origin" is listed and enabled.
3. In each browser, visit a page known to contain ads/trackers and confirm they're
   blocked.

Expected outcome: matches spec.md User Story 1 Acceptance Scenarios 1–3.

## 4. Validate User Story 2 — Bitwarden extension (P2)

1. In Chrome and in Firefox, click the Bitwarden extension icon.
2. Confirm it opens and prompts for login (or is already logged in).
3. Log in (or confirm already logged in) and visit a site with a saved login; confirm
   autofill works from the extension in both browsers.

Expected outcome: matches spec.md User Story 2 Acceptance Scenarios 1–3.

## 5. Validate User Story 3 — Dark Reader (P3)

1. In Chrome and in Firefox, visit a light-themed site with no built-in dark mode.
2. Confirm Dark Reader is installed/enabled (`chrome://extensions`, `about:addons`) and
   the page renders in a dark theme.

Expected outcome: matches spec.md User Story 3 Acceptance Scenarios 1–3.

## 6. Validate User Story 4 — Vimium / Vimium-FF (P4)

1. In Chrome, trigger a Vimium keyboard shortcut (e.g., `f` for link hints) on a normal
   page and confirm it responds.
2. In Firefox, do the same with Vimium-FF.

Expected outcome: matches spec.md User Story 4 Acceptance Scenarios 1–3.

## 7. Validate re-declaration after manual disable (Edge Cases)

1. Manually disable one extension in one browser (e.g., Dark Reader in Chrome).
2. Re-run `sudo nixos-rebuild switch --flake .#laptop` (no config changes needed).
3. Relaunch the browser and confirm the extension is enabled again.

Expected outcome: matches spec.md Edge Cases — declarative config is the source of
truth on every rebuild.
