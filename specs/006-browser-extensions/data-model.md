# Phase 1 Data Model: Browser Extensions (Chrome & Firefox)

This feature introduces no application-level data model, database, or schema — it
provisions browser policy configuration. The "entities" below are the configuration-level
concepts from the feature spec, included for traceability back to `spec.md`'s Key
Entities, not as data this repository stores or manages.

## Entities

### Extension Family

Represents one of the four extension families this feature installs. Note that two
families resolve to a *different concrete extension per browser* (see `research.md`).

| Field | Description |
|---|---|
| `family` | Human-readable name (Content Blocker, Bitwarden, Dark Reader, Vimium-style Navigation) |
| `chromeExtensionId` | Chrome Web Store ID used in `programs.chromium.extensions` |
| `firefoxGuid` | Firefox add-on `guid`, the key under `programs.firefox.policies.ExtensionSettings` |
| `firefoxInstallUrl` | AMO "latest.xpi" URL for the Firefox add-on, built from its slug |

Relationships: each Extension Family is declared once, in
`modules/nixos/browser-extensions.nix`, contributing one entry to
`programs.chromium.extensions` and one entry to
`programs.firefox.policies.ExtensionSettings`. Families are independent of each other
(spec Edge Cases) — no cross-family relationship.

### Target Browser

Represents Chrome or Firefox — the two browsers this feature extends. Both already exist
(provisioned by `specs/005-chrome-obsidian-bitwarden` and `modules/nixos/users.nix`
respectively) and are not created or modified in identity here, only granted extensions.

| Field | Description |
|---|---|
| `browser` | `chrome` or `firefox` |
| `policyMechanism` | `programs.chromium.extensions` (Chrome) or `programs.firefox.policies.ExtensionSettings` (Firefox) |
| `policyFile` | Resulting file on disk (`/etc/opt/chrome/policies/managed/default.json` or `/etc/firefox/policies/policies.json`) |

### Extension Runtime State (out of scope for provisioning)

Represents each installed extension's own local state (settings, Bitwarden login
session), which this feature does not create, seed, or manage — included only because
spec Edge Cases require it to be called out.

| Field | Description |
|---|---|
| `extension` | Which Extension Family / Target Browser this belongs to |
| `location` | Inside the relevant browser's profile directory under `dmiller`'s `$HOME` |
| `persistence` | Not guaranteed or managed by this feature (spec Edge Cases / Assumptions) |

No state transitions apply — these are extension-managed runtime artifacts, not records
this feature's own logic reads or writes.
