# Phase 0 Research: Browser Extensions (Chrome & Firefox)

## Decision: Chrome cannot run the full uBlock Origin at all

- **Decision**: Chrome gets `uBlock Origin Lite`; Firefox gets the full `uBlock Origin`.
- **Rationale**: Verified via web search (Sept 2026): Google removed the classic
  (Manifest V2) uBlock Origin from the Chrome Web Store in late 2024 and permanently
  disabled remaining MV2 extensions in Chrome in July 2025. The last enterprise-policy
  workarounds (`ExtensionManifestV2Availability` and related flags) were themselves
  removed in Chrome 150/151 (June–July 2026). This means force-installing the original
  uBlock Origin via `ExtensionInstallForcelist` will not work on current Chrome — it is
  not installable by any mechanism, Nix included. uBlock Origin Lite (Manifest V3) is
  the official successor, built and maintained by the same developer, and remains
  available and installable. Firefox has committed to continuing Manifest V2 support, so
  the full uBlock Origin still works there. Confirmed directly with the user (see spec.md
  Assumptions) before proceeding.
- **Alternatives considered**:
  - Force-install the original uBlock Origin in Chrome anyway: rejected — confirmed
    infeasible; Chrome will not run it under any current mechanism.
  - Use a different Chrome-compatible ad blocker (e.g., AdGuard): rejected by the user in
    favor of uBlock Origin Lite, which keeps the "same project/developer" continuity with
    the Firefox side.
  - Drop Chrome ad-blocking from this feature entirely: rejected by the user in favor of
    keeping Chrome covered via the Lite version.

## Decision: Vimium vs. Vimium-FF

- **Decision**: Chrome gets `Vimium`; Firefox gets `Vimium-FF`.
- **Rationale**: Vimium itself is a Chrome-only extension; Firefox never had an official
  port. "Vimium-FF" (AMO slug `vimium-ff`) is the long-standing, actively used community
  port providing equivalent keyboard-navigation functionality. This is a pre-existing
  ecosystem split (documented on Vimium's own GitHub and AMO), not a choice introduced by
  this feature.
- **Alternatives considered**: A different Firefox keyboard-navigation extension (e.g.,
  Tridactyl, Vimium C): rejected — "Vimium-FF" is the closest-named, closest-behavior
  equivalent and matches the feature description's intent.

## Decision: Installation mechanism per browser

- **Decision**: Use each browser's native, already-available NixOS policy option —
  `programs.chromium.extensions` for Chrome, `programs.firefox.policies.ExtensionSettings`
  for Firefox. No new flake input.
- **Rationale**: Verified by reading the actual `nixpkgs` module source at the pinned
  revision (`8ce4ef6cb6f871616146b9fe26d2a5ae594e94fe`,
  `nixos/modules/programs/chromium.nix` and `nixos/modules/programs/firefox.nix`):
  - `programs.chromium.enable = true;` with `programs.chromium.extensions = [ "<id>" ... ];`
    writes an `ExtensionInstallForcelist` policy to
    `/etc/opt/chrome/policies/managed/default.json` (the path Google Chrome itself reads
    on Linux — confirmed in the module source, which writes this file specifically "for
    google-chrome"), as well as the equivalent paths for the `chromium` and `brave`
    packages. Enabling this option does **not** install the `chromium` package itself —
    it only writes `environment.etc` policy files — so it has no effect on which browser
    packages end up installed.
  - `programs.firefox.policies.ExtensionSettings = { "<guid>" = { install_url = "..."; installation_mode = "force_installed"; }; };`
    writes `/etc/firefox/policies/policies.json`, which Firefox reads as a Linux
    system policy (works with the existing `programs.firefox.enable = true;` in
    `modules/nixos/users.nix`).
  - Both mechanisms are read-only, IT-managed-style policies: Chrome/Firefox fetch and
    install the actual extension code from their respective stores at first launch, then
    keep it updated themselves — same as how any already-installed browser fetches web
    content, not a Nix build-time dependency.
- **Alternatives considered**:
  - Home-manager's `programs.firefox.profiles.<name>.extensions.packages` (pulling `.xpi`
    files fully into the Nix store via the community NUR `firefox-addons` overlay):
    rejected for this pass — it would fully reproducibly pin the Firefox extensions, but
    requires adding NUR as a new flake input for Firefox only, while Chrome has no
    equivalent Nix-packaged-extension mechanism at all (force-install policy is the only
    real option there). Using one consistent "enterprise policy" mechanism for both
    browsers is simpler (Constitution Principle V) than mixing two different extension
    delivery strategies. This can be revisited later if reproducible-pinned Firefox
    extensions become a priority.
  - Packaging the `.xpi`/`.crx` files directly as local Nix derivations: rejected as
    unnecessary complexity — both browsers already ship first-class, documented NixOS
    options for exactly this use case.

## Decision: Concrete extension identifiers

Verified via the Chrome Web Store, addons.mozilla.org, and the Mozilla Add-ons v5 API
(`https://addons.mozilla.org/api/v5/addons/addon/<slug>/`, field `guid`) as of 2026-09-17:

| Extension family | Chrome Web Store ID | Firefox (AMO) guid | Firefox (AMO) slug |
|---|---|---|---|
| Content blocker | `ddkjiahejlhfcafbddmgiahcphecmpfh` (uBlock Origin Lite) | `uBlock0@raymondhill.net` (uBlock Origin) | `ublock-origin` |
| Bitwarden | `nngceckbapebfimnlniiiahkandclblb` | `{446900e4-71c2-419f-a6a7-df9c091e268b}` | `bitwarden-password-manager` |
| Dark Reader | `eimadpbcbfnmbkopoojfekhnkhdbieeh` | `addon@darkreader.org` | `darkreader` |
| Vimium / Vimium-FF | `dbepggeogbaibhgnhhndojpepiihcmeb` | `{d7742d87-e61d-4b78-b8a1-b469842139fa}` | `vimium-ff` |

The Firefox `install_url` for each is
`https://addons.mozilla.org/firefox/downloads/latest/<slug>/latest.xpi`, Mozilla's
standard "always current signed build" download URL for a given add-on slug.

- **Alternatives considered**: None — these are fixed, externally-defined identifiers,
  not a design choice; they only needed accurate lookup, which was done via primary
  sources (the stores themselves and Mozilla's official API) rather than assumed from
  memory.

## Decision: Validation approach

- **Decision**: Validate via `nix flake check` plus `nixos-rebuild dry-build
  --flake .#laptop` (Constitution Principle IV, matching the pattern from
  `specs/005-chrome-obsidian-bitwarden`), then manually confirm each extension appears
  and is enabled in both browsers post-`switch`, per the acceptance scenarios in
  `spec.md`.
- **Rationale**: No test framework applies to declarative policy configuration; the
  meaningful validation is that the config evaluates/builds and that each browser
  actually force-installs and enables each extension after a real rebuild. This part
  cannot be verified by an automated build check alone — it requires launching each
  browser.
- **Alternatives considered**: Automated browser-extension testing (e.g., a scripted
  Selenium/Playwright check that each extension is present): rejected as disproportionate
  for a personal-laptop config change (Constitution Principle V); no such harness exists
  in this repo today.
