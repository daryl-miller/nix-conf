# Feature Specification: Hyprland Desktop Environment

**Feature Branch**: `004-hyprland-desktop`

**Created**: 2026-09-17

**Status**: Draft

**Input**: User description: "I would like to add hyperland as a desktop environment with sane defaults/settings recommends similar to omarchy but I would like to be presented with options for nice to haves, good additions, plugins etc."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Log in to a working Hyprland session (Priority: P1)

As the developer using this laptop, I want to select Hyprland as my desktop session and land
in a fully functional, already-configured environment, so that I don't have to hand-write
window manager configuration before I can get any work done.

**Why this priority**: This is the entire point of the feature. Without a working session
that comes pre-configured, nothing else in this feature has value.

**Independent Test**: On a freshly rebuilt system, select the Hyprland session from the login
screen and confirm the compositor starts, a status bar is visible, and a terminal can be
opened via keybinding — with zero manual configuration.

**Acceptance Scenarios**:

1. **Given** a freshly rebuilt laptop, **When** the developer selects the Hyprland session at
   login, **Then** the session starts successfully and shows a status bar, wallpaper, and
   responsive desktop.
2. **Given** an active Hyprland session, **When** the developer uses the default keybindings,
   **Then** they can open a terminal, open an application launcher, switch workspaces, move
   and resize windows, and close windows without consulting external documentation.

---

### User Story 2 - Work day-to-day without missing basic desktop conveniences (Priority: P1)

As the developer, I want the baseline "sane defaults" that any usable desktop environment
provides — screen locking, notifications, screenshots, and a consistent look — configured out
of the box, so the session feels complete rather than like a bare window manager.

**Why this priority**: A window manager with no lock screen, no notifications, and no
screenshot capability is not yet a usable desktop environment, which is what was asked for.
This is tied for P1 with User Story 1 because "sane defaults" is explicitly the ask.

**Independent Test**: On a freshly rebuilt system, confirm the session auto-locks after
inactivity, a manual lock keybinding works, a screenshot can be captured via keybinding, and
an application notification (e.g., from a background process) is visibly displayed.

**Acceptance Scenarios**:

1. **Given** an idle Hyprland session, **When** the configured inactivity period elapses,
   **Then** the screen locks automatically.
2. **Given** an active Hyprland session, **When** the developer presses the screenshot
   keybinding, **Then** a screenshot of the full screen or a selected region is captured.
3. **Given** an active Hyprland session, **When** an application sends a desktop
   notification, **Then** it is displayed to the developer.

---

### User Story 3 - Choose which nice-to-have companion tools to include (Priority: P2)

As the developer, I want to be shown a curated set of optional companion tools and Hyprland
plugins beyond the sane defaults (e.g., clipboard history, screen recording, extra bar
widgets, alternate tiling behavior), so that I can pick the additions I actually want rather
than getting an opinionated bundle imposed on me or having to discover and research them
myself.

**Why this priority**: This is explicitly requested by the developer but is additive on top
of a working baseline session (User Stories 1–2), so it is P2.

**Independent Test**: Review the presented options for nice-to-have tools/plugins, confirm a
selection was made, and verify only the selected tools are present and functional after
rebuild.

**Acceptance Scenarios**:

1. **Given** the feature is being specified, **When** optional companion tools/plugins are
   proposed, **Then** the developer is presented with a clear set of options (not a single
   unavoidable bundle) and can accept, reject, or mix and match.
2. **Given** the developer has selected a set of nice-to-have tools, **When** the system is
   rebuilt, **Then** exactly those tools are installed and functional, and unselected ones
   are absent.

---

### Edge Cases

- What happens if Hyprland fails to start (e.g., unsupported graphics driver) — is there a
  fallback session the developer can still log into?
- How does the session behave when an external monitor is connected or disconnected while
  Hyprland is running?
- How does closing the laptop lid while in a Hyprland session interact with existing
  suspend/power behavior?
- What happens to clipboard history and active notifications across a lock/unlock cycle?
- What happens if a selected nice-to-have plugin is incompatible with the Hyprland version
  provided by the pinned `nixpkgs` input?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide Hyprland as an available desktop session, selectable at
  login alongside the existing KDE Plasma 6 session, that starts successfully on the
  laptop host's existing graphics hardware. Plasma 6 MUST remain available as a fallback
  session; Hyprland MUST NOT replace it.
- **FR-002**: System MUST provide default keybindings, working immediately after rebuild with
  no manual configuration, for at minimum: opening a terminal, opening an application
  launcher, closing the focused window, switching between workspaces, moving a window between
  workspaces, moving/resizing windows, and locking the screen.
- **FR-003**: System MUST include a default status bar visible at all times, showing at
  minimum the active workspace, a clock, and system status indicators (network, power/battery,
  volume).
- **FR-004**: System MUST include a default application launcher, reachable via a keybinding,
  for finding and starting installed applications.
- **FR-005**: System MUST lock the session automatically after a period of inactivity and MUST
  also support locking on demand via a keybinding.
- **FR-006**: System MUST apply a default wallpaper and a consistent baseline visual style
  (bar, launcher, lock screen) so the session looks intentionally configured on first login
  rather than bare or mismatched.
- **FR-007**: System MUST provide a way to capture a screenshot of the full screen and of a
  manually selected region, via keybinding.
- **FR-008**: System MUST display desktop notifications sent by applications.
- **FR-009**: System MUST include the following nice-to-have companion tools beyond the
  baseline defaults in FR-001–FR-008: a clipboard history manager, a screen recording tool, a
  color picker, additional status-bar widgets (media playback controls and CPU/memory/
  temperature indicators), Bluetooth/network tray applets, and extra Hyprland plugins (e.g.,
  an alternate tiling layout, animated window borders).
- **FR-010**: System MUST apply an opinionated, Omarchy-style visual theme (a cohesive color
  palette, font choice, rounded corners, and window animations) consistently across the
  Hyprland session's visible components (bar, launcher, lock screen, terminal).
- **FR-011**: Configuration for the Hyprland session and its companion tools MUST be fully
  declarative and applied via the existing NixOS/home-manager rebuild workflow, requiring no
  imperative setup steps or hand-written config files outside the repository.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After a rebuild, the developer can go from login screen to a usable desktop
  (bar visible, terminal reachable) in under 30 seconds, with zero manual configuration steps.
- **SC-002**: The developer can perform every core window-management action (launch an app,
  switch workspaces, move/resize a window, lock the screen, take a screenshot) using only
  keyboard shortcuts, without looking up Hyprland-specific documentation.
- **SC-003**: On first login after rebuild, the session's appearance (wallpaper, bar, lock
  screen) is visually consistent and complete, requiring no manual theming to reach a
  presentable state.
- **SC-004**: 100% of the nice-to-have tools/plugins the developer selects are present and
  functional after rebuild, and no unselected tool is installed.
- **SC-005**: If Hyprland fails to start, the developer can still reach a working graphical
  session (existing or fallback) without needing out-of-band recovery (e.g., a live USB).

## Assumptions

- This feature targets the existing `laptop` host only; extending Hyprland to a future
  second host is out of scope here and would be handled when that host is onboarded
  (Constitution Principle III).
- The developer (`dmiller`) is the only user of this session; multi-user session
  considerations are out of scope.
- Hyprland's Wayland-only nature is acceptable; XWayland compatibility for legacy X11
  applications is assumed sufficient and full X11 session parity is not required.
- "Similar to Omarchy" refers to adopting comparable *categories* of sane defaults (bar,
  launcher, lock/idle behavior, notifications, cohesive theming) rather than reusing
  Omarchy's Arch-specific installer or scripts, since all configuration here must remain
  declarative Nix (Constitution Principle I).
- The existing keyboard layout and other host-level settings currently defined for the
  desktop session (e.g., `au` layout) carry over unchanged.
- No new secrets are introduced by this feature (Secrets Management is not applicable).
