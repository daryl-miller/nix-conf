# Feature Specification: Browser Extensions (Chrome & Firefox)

**Feature Branch**: `006-browser-extensions`

**Created**: 2026-09-17

**Status**: Draft

**Input**: User description: "Add declarative browser extension management for Chrome
and Firefox: install and enable the Bitwarden password manager extension, uBlock Origin
(ad/content blocker), Dark Reader (dark mode for websites), and Vimium (keyboard
navigation) in both browsers."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse with ads and trackers blocked (Priority: P1)

As the developer using this laptop, I want a content blocker active in both Chrome and
Firefox as soon as I open them, so that I get a fast, ad- and tracker-blocked browsing
experience everywhere without installing it by hand in each browser.

**Why this priority**: Content blocking is the extension with the broadest, most
constant impact on daily browsing (every page load, both browsers) and the one the
developer would otherwise miss most if it were absent after a rebuild.

**Independent Test**: On a freshly rebuilt system, open Chrome and separately open
Firefox, visit a page known to contain ads/trackers, and confirm the content blocker is
present, enabled, and actively blocking content in both browsers with no manual install
step.

**Acceptance Scenarios**:

1. **Given** a freshly rebuilt laptop, **When** the developer opens Chrome, **Then**
   uBlock Origin Lite is already installed and enabled.
2. **Given** a freshly rebuilt laptop, **When** the developer opens Firefox, **Then**
   the full uBlock Origin is already installed and enabled.
3. **Given** the content blocker is active, **When** the developer visits a page with
   known ads/trackers, **Then** those elements are blocked.

---

### User Story 2 - Access passwords via the Bitwarden extension (Priority: P2)

As the developer, I want the Bitwarden browser extension installed and enabled in both
Chrome and Firefox, so that I can fill in saved credentials while browsing without
installing the extension by hand.

**Why this priority**: Password autofill is a frequent daily convenience and a security
good practice (avoiding retyping/copy-pasting passwords), but the developer can still get
by briefly using the Bitwarden desktop app (see `specs/005-chrome-obsidian-bitwarden`) or
manual copy/paste in the interim — hence below content blocking.

**Independent Test**: On a freshly rebuilt system, open Chrome and separately open
Firefox, click the Bitwarden extension icon in each, and confirm it opens and prompts for
(or already has) login — with no manual install step.

**Acceptance Scenarios**:

1. **Given** a freshly rebuilt laptop, **When** the developer opens Chrome, **Then** the
   Bitwarden extension is already installed and enabled.
2. **Given** a freshly rebuilt laptop, **When** the developer opens Firefox, **Then** the
   Bitwarden extension is already installed and enabled.
3. **Given** the developer is logged in to Bitwarden in the extension, **When** they
   visit a site with a saved login, **Then** they can autofill it from the extension.

---

### User Story 3 - Browse comfortably at night with Dark Reader (Priority: P3)

As the developer, I want Dark Reader installed and enabled in both Chrome and Firefox, so
that sites without their own dark mode are automatically displayed in a dark theme
without installing it by hand.

**Why this priority**: A comfort/accessibility feature that improves the experience but
has no functional or security impact if temporarily missing — lowest priority of the
four extensions along with Vimium.

**Independent Test**: On a freshly rebuilt system, open Chrome and separately open
Firefox, visit a light-themed site with no built-in dark mode, and confirm Dark Reader is
installed, enabled, and rendering the page in a dark theme.

**Acceptance Scenarios**:

1. **Given** a freshly rebuilt laptop, **When** the developer opens Chrome, **Then** Dark
   Reader is already installed and enabled.
2. **Given** a freshly rebuilt laptop, **When** the developer opens Firefox, **Then**
   Dark Reader is already installed and enabled.
3. **Given** Dark Reader is active, **When** the developer visits a light-themed site,
   **Then** the page is displayed with a dark theme applied.

---

### User Story 4 - Navigate pages by keyboard with Vimium (Priority: P4)

As the developer, I want Vimium installed and enabled in both Chrome and Firefox, so that
I can navigate and interact with web pages using keyboard shortcuts without installing it
by hand.

**Why this priority**: A power-user productivity feature the developer can live without
temporarily (using the mouse/trackpad instead); narrowest-impact of the four extensions,
so it ranks last.

**Independent Test**: On a freshly rebuilt system, open Chrome and separately open
Firefox, and confirm Vimium's keyboard navigation (e.g., link hints, scrolling) responds
on a normal web page with no manual install step.

**Acceptance Scenarios**:

1. **Given** a freshly rebuilt laptop, **When** the developer opens Chrome, **Then**
   Vimium is already installed and enabled.
2. **Given** a freshly rebuilt laptop, **When** the developer opens Firefox, **Then**
   Vimium is already installed and enabled.
3. **Given** Vimium is active, **When** the developer triggers a Vimium keyboard shortcut
   (e.g., link-hint mode) on a page, **Then** Vimium responds as expected.

---

### Edge Cases

- What happens if the developer manually disables or removes one of these extensions
  during a session? A subsequent rebuild MUST re-enable/reinstall it — the declarative
  configuration is the source of truth, consistent with Constitution Principle I; the
  developer may still disable an extension for the remainder of a running session without
  that being "fixed" mid-session.
- What happens to each extension's own settings/state (e.g., uBlock Origin custom filter
  lists, Dark Reader per-site toggles, Bitwarden's logged-in session)? This feature only
  guarantees the extensions are installed and enabled; per-extension user settings and
  login state are extension-managed and are not provisioned, reset, or guaranteed to
  persist by this feature (see Assumptions).
- What happens if an extension conflicts with another (e.g., Vimium's keybindings versus
  a site's own shortcuts)? Extension-level conflict handling is left to each extension's
  own settings; this feature does not add conflict-resolution configuration beyond
  installing and enabling all four.
- What happens on the very first browser launch after a rebuild, before the developer
  has signed in to sync (Chrome) or a Firefox account? All four extensions MUST still be
  installed and enabled without requiring any browser account sign-in — this feature does
  not depend on browser-account-based sync to deliver the extensions.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The laptop configuration MUST declaratively install and enable a content
  blocker in both Chrome and Firefox for `dmiller`, active immediately after a rebuild
  with no imperative install step: uBlock Origin Lite in Chrome and the full uBlock
  Origin in Firefox (see Assumptions — Chrome can no longer run the full version at
  all, regardless of installation mechanism).
- **FR-002**: The laptop configuration MUST declaratively install and enable the
  Bitwarden browser extension in both Chrome and Firefox for `dmiller`, active
  immediately after a rebuild with no imperative install step.
- **FR-003**: The laptop configuration MUST declaratively install and enable Dark Reader
  in both Chrome and Firefox for `dmiller`, active immediately after a rebuild with no
  imperative install step.
- **FR-004**: The laptop configuration MUST declaratively install and enable Vimium-style
  keyboard navigation in both Chrome and Firefox for `dmiller`, active immediately after
  a rebuild with no imperative install step (Chrome: Vimium; Firefox: the community
  Firefox port, "Vimium-FF" — see Assumptions).
- **FR-005**: None of these extensions may require the developer to sign in to a
  browser-level account (Chrome sync, Firefox account) for the extension itself to be
  present and enabled.
- **FR-006**: Installing these extensions MUST NOT remove, disable, or otherwise degrade
  Chrome, Firefox, or any other currently working browser extension or configuration
  (including the applications provisioned in `specs/005-chrome-obsidian-bitwarden`).
- **FR-007**: All four extensions, in both browsers, MUST be expressed declaratively
  (Nix packages/modules/policies) per Constitution Principle I; none may depend on a
  hand-run install (e.g., manually visiting a web store) to be present after a rebuild.
- **FR-008**: The resulting configuration MUST successfully evaluate and dry-build for
  the laptop host before this feature is considered complete, per Constitution
  Principle IV.

### Key Entities

- **Browser Extension**: One of the four extension families (content blocker, Bitwarden,
  Dark Reader, Vimium-style navigation) provisioned by this feature; each is installed
  and enabled independently of the others, in both target browsers. Two families use a
  different concrete extension per browser (content blocker: uBlock Origin Lite on
  Chrome vs. full uBlock Origin on Firefox; navigation: Vimium on Chrome vs. Vimium-FF on
  Firefox) because the original extension isn't available/installable on both browsers.
- **Target Browser**: Chrome or Firefox — the two browsers into which each extension is
  installed for `dmiller`; both existing installations already provisioned
  (`specs/005-chrome-obsidian-bitwarden` for Chrome, `modules/nixos/users.nix` for
  Firefox) and unmodified in identity by this feature beyond gaining extensions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After a fresh rebuild, `dmiller` finds all four extension families (content
  blocker, Bitwarden, Dark Reader, Vimium-style navigation) already installed and enabled
  the first time they open either Chrome or Firefox, with zero manual installation steps.
- **SC-002**: A developer can block ads/trackers, autofill a saved password, view a
  light-themed site in dark mode, and use a keyboard shortcut to navigate a page — each
  on the first attempt, in both Chrome and Firefox, immediately after installation.
- **SC-003**: Reproducing this environment on a clean rebuild of the laptop host requires
  zero manual, undeclared installation or configuration steps for any of the four
  extensions in either browser.

## Assumptions

- This feature applies to the `dmiller` user on the existing `laptop` host only, and
  extends the Chrome and Firefox installations already provisioned by
  `specs/005-chrome-obsidian-bitwarden` and `modules/nixos/users.nix` respectively —it
  does not install or configure any other browser.
- "Install and enable" means the extension is present and active by default after a
  rebuild; it does not mean any of the four extensions are pre-configured with specific
  custom settings (e.g., uBlock Origin custom filter subscriptions, Dark Reader
  brightness/contrast preferences, Vimium custom key mappings) beyond each extension's
  own out-of-the-box defaults — the developer can still adjust per-extension settings
  through each extension's own UI, and those adjustments are not guaranteed to be
  declared or persisted by this feature.
- The Bitwarden *browser extension* here is a separate, additional integration from the
  Bitwarden *desktop app* covered by `specs/005-chrome-obsidian-bitwarden`; both may be
  used together (e.g., the desktop app for full vault management, the extension for
  in-browser autofill), and this feature does not change or replace the desktop app.
- No extension requires any secret to be stored in this repository; each extension's own
  login/session state (e.g., Bitwarden's logged-in session) is created by the developer
  at first use, not seeded or managed by this feature, consistent with Constitution
  Secrets Management guidance.
- "Both browsers" means exactly Chrome and Firefox as they exist on the `laptop` host
  today; no other Chromium- or Gecko-based browser is in scope.
- Google removed the full (Manifest V2) uBlock Origin from Chrome entirely in 2026,
  including every enterprise/policy-based workaround — this is a Chrome platform
  restriction, not a limitation of this repo's tooling. Chrome therefore gets uBlock
  Origin Lite (the official Manifest V3 successor, maintained by the same developer,
  with a smaller filter-list/rule capacity than the original); Firefox continues to
  support the full uBlock Origin and gets that version. "Content blocker" in the user
  scenarios above refers to whichever of the two is installed per browser.
- Firefox does not run the original Vimium (a Chrome-only extension); it gets
  "Vimium-FF," a separate, community-maintained port that provides equivalent
  keyboard-navigation functionality. This is a pre-existing ecosystem split, not a
  choice this feature is making.
