# Phase 1 Data Model: Chrome, Obsidian & Bitwarden Desktop Apps

This feature introduces no application-level data model, database, or schema — it
provisions three third-party desktop applications. The "entities" below are the
configuration-level concepts from the feature spec, included for traceability back to
`spec.md`'s Key Entities, not as data this repository stores or manages.

## Entities

### Desktop Application Package

Represents one of the three applications this feature installs.

| Field | Description |
|---|---|
| `name` | Human-readable application name (Chrome, Obsidian, Bitwarden Desktop App) |
| `nixpkgsAttribute` | The `nixpkgs` package attribute used (`google-chrome`, `obsidian`, `bitwarden-desktop`) — see `research.md` |
| `host` | Which host installs it (`laptop`, per spec Assumptions) |
| `user` | Which user can launch it (`dmiller`, per spec Assumptions) |

Relationships: each Desktop Application Package is declared once, in
`modules/nixos/desktop-apps.nix`, and imported by exactly one host configuration
(`hosts/laptop/configuration.nix`) in this feature. No relationships between the three
packages themselves (they are installed and used independently — spec Edge Cases).

### Application User Data (out of scope for provisioning)

Represents each application's own local state, which this feature does not create,
seed, or manage — included only because spec FR-004 and the Edge Cases require it to
survive rebuilds.

| Field | Description |
|---|---|
| `application` | Which Desktop Application Package this data belongs to |
| `location` | Path under `dmiller`'s `$HOME` (application-defined, not configured by this repo) |
| `persistence` | MUST survive a laptop rebuild (spec FR-004) — guaranteed by existing `$HOME` durability, not by any mechanism this feature adds |

No state transitions apply — these are inert, application-managed files/directories, not
records this feature's own logic reads or writes.
