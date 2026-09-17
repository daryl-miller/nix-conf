# Feature Specification: Chrome, Obsidian & Bitwarden Desktop Apps

**Feature Branch**: `005-chrome-obsidian-bitwarden`

**Created**: 2026-09-17

**Status**: Draft

**Input**: User description: "I want to add chrome, obsidian and bitwarden"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse the web with Chrome (Priority: P1)

As the developer using this laptop, I want Google Chrome available as an installed
application, so that I can browse the web and use Chrome-specific tooling/extensions
(e.g., web development devtools, Chrome-only sites) without installing it by hand.

**Why this priority**: A web browser is used constantly for day-to-day work and is the
most broadly useful of the three applications; the desktop is already usable with the
existing Firefox install, but Chrome fills a specific gap (Chrome-only sites/tooling).

**Independent Test**: On a freshly rebuilt system, launch Chrome from the application
launcher and confirm it opens, loads a web page, and persists state (e.g., a bookmark or
signed-in session) across restarts.

**Acceptance Scenarios**:

1. **Given** a freshly rebuilt laptop, **When** the developer launches Chrome from the
   desktop environment, **Then** it opens and successfully loads a web page.
2. **Given** Chrome is open, **When** the developer closes and relaunches it, **Then**
   previously set state (bookmarks, open profile) is preserved.

---

### User Story 2 - Take notes with Obsidian (Priority: P2)

As the developer, I want Obsidian available as an installed application, so that I can
create and edit a local Markdown-based notes vault without installing it by hand.

**Why this priority**: Note-taking is valuable daily-use tooling but is not required for
the machine's core development or browsing workflows to function, so it ranks below the
browser.

**Independent Test**: On a freshly rebuilt system, launch Obsidian, create a new vault (or
open an existing one), create a note, and confirm the note is saved to disk as a Markdown
file.

**Acceptance Scenarios**:

1. **Given** a freshly rebuilt laptop, **When** the developer launches Obsidian, **Then**
   it opens and allows creating or opening a vault.
2. **Given** an open vault, **When** the developer creates and saves a note, **Then** the
   note exists on disk as a Markdown file after Obsidian is closed and reopened.

---

### User Story 3 - Manage passwords with Bitwarden (Priority: P3)

As the developer, I want the Bitwarden desktop application available as an installed
application, so that I can access and manage my password vault locally without installing
it by hand.

**Why this priority**: Password management is important but the developer has existing
ways to retrieve credentials in the interim (e.g., another device, the browser extension
once installed manually); it is the narrowest and most self-contained of the three
applications.

**Independent Test**: On a freshly rebuilt system, launch the Bitwarden desktop app, log in
to an existing Bitwarden account, and confirm vault items are visible.

**Acceptance Scenarios**:

1. **Given** a freshly rebuilt laptop, **When** the developer launches the Bitwarden
   desktop app, **Then** it opens and presents a login screen.
2. **Given** valid Bitwarden account credentials, **When** the developer logs in,
   **Then** their existing vault items are visible in the app.

---

### Edge Cases

- What happens if the developer has no existing Bitwarden or Obsidian account/vault yet?
  Both apps MUST still launch and allow first-time setup (account creation for Bitwarden,
  new vault creation for Obsidian) — this feature only provisions the applications, not
  any account or vault data.
- What happens to Chrome, Obsidian, or Bitwarden application data (profiles, vault files,
  local cache) across a laptop rebuild? Per-application user data lives outside the Nix
  store (e.g., under the user's home directory) and MUST persist across rebuilds, the same
  as other user-level application state on this system.
- What happens if Chrome and Firefox are both installed? Both MUST remain independently
  usable; this feature does not remove or disable the existing Firefox install.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The laptop configuration MUST declaratively provide Google Chrome, available
  to launch from the desktop environment for `dmiller` immediately after a rebuild, with no
  imperative post-install step.
- **FR-002**: The laptop configuration MUST declaratively provide Obsidian, available to
  launch from the desktop environment for `dmiller` immediately after a rebuild, with no
  imperative post-install step.
- **FR-003**: The laptop configuration MUST declaratively provide the Bitwarden desktop
  application, available to launch from the desktop environment for `dmiller` immediately
  after a rebuild, with no imperative post-install step.
- **FR-004**: Each application's user-level data (browser profile, notes vault contents,
  Bitwarden local vault cache) MUST persist across a laptop rebuild, consistent with how
  other user-level application state on this system is handled.
- **FR-005**: Installing these applications MUST NOT remove, disable, or otherwise degrade
  the existing Firefox installation or any other currently working application.
- **FR-006**: All three applications MUST be expressed declaratively (Nix
  packages/modules) per Constitution Principle I; none may depend on a hand-run install or
  configuration script to function correctly after a rebuild.
- **FR-007**: The resulting configuration MUST successfully evaluate and dry-build for the
  laptop host before this feature is considered complete, per Constitution Principle IV.

### Key Entities

- **Chrome**: The Google Chrome web browser application, installed and launchable for
  `dmiller`, independent of the existing Firefox install.
- **Obsidian**: The Obsidian note-taking application, installed and launchable for
  `dmiller`; operates on a local Markdown-file vault whose location/creation is
  user-driven, not provisioned by this feature.
- **Bitwarden Desktop App**: The Bitwarden password-manager desktop application, installed
  and launchable for `dmiller`; authenticates against the developer's existing Bitwarden
  account and does not itself hold or manage this repository's secrets.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After a fresh rebuild, `dmiller` can launch Chrome, Obsidian, and Bitwarden
  from the desktop environment with zero manual installation steps.
- **SC-002**: A developer can browse the web in Chrome, create and persist a note in
  Obsidian, and log in to view vault items in Bitwarden, each on the first attempt after
  installation.
- **SC-003**: Reproducing this environment on a clean rebuild of the laptop host requires
  zero manual, undeclared installation or configuration steps for any of the three
  applications.

## Assumptions

- This feature applies to the `dmiller` user on the existing `laptop` host only, within
  the desktop environment established in `specs/004-hyprland-desktop`.
- "Bitwarden" refers to the official Bitwarden desktop application (vault access GUI), not
  a browser extension or CLI; a browser extension may be added separately later if desired
  but is out of scope here.
- The Bitwarden desktop app manages the developer's personal password vault via their own
  Bitwarden account; it is unrelated to, and does not replace, this repository's own
  Secrets Management mechanism (Constitution: Secrets Management section) for handling
  secrets that live in this repo.
- No vault, notes, or account data is created, seeded, or migrated by this feature — it
  only provisions the applications themselves; account sign-in and vault/note creation are
  manual, first-run user actions outside the scope of declarative configuration.
- These applications are added as GUI packages (system-level or home-manager, whichever is
  the established pattern for desktop applications in this repo) rather than through any
  browser-extension or sandboxed-store mechanism.
