# Tactical UI visual polish

**Branch:** `chatgpt/ui-visual-polish-20261122`, stacked above the mobile
experience-polish branch. Source art remains in Godot controls, not raster images.

## Art direction

An unobtrusive field-operations console: midnight steel background,
desaturated blue-slate panels, thin left-edge status bars, high-contrast
near-white text, cyan information/selection, amber primary decisions,
and red only for destructive combat actions. Accent is functional rather
than decorative. Every visual token is in `src/view/menu/ui_skin.gd`.

## Surfaces

- Launcher: centered command panel with restrained metadata and dominant
  Enter Battle CTA; both voxel test entry points remain available.
- Force assembly: a full-width heading, distinct roster sections, unified
  unit catalog cards and a primary Start Battle CTA.
- Battle: highlighted phase/status header, quieter selection/help copy,
  translucent combat telemetry, accent-edged side sheet and action tray.
- Weapon selection: selected rows, legible hit odds and muted explanatory
  notes; the underlying attack declarations are unchanged.
- Replay: high-contrast transport strip with prominent Play and clear Exit.
- Academy, training, pause, and lesson cards: shared heading and control hierarchy.

## Visual QA

- Verify on 1280×720 landscape that all movement/weapon buttons fit, the
  actual 3D map remains visible, and no text is cut off.
- Verify 720p and a narrow Android landscape safe area with a notch;
  test expanded combat log and record sheet scrolling.
- Verify accessibility of subdued copy and disabled controls outdoors.
- Run `godot --headless --import`, `godot --headless -s tests/run_tests.gd`,
  `godot --headless -s tools/ui_smoke.gd` and launcher/Academy smoke scenes.
- No combat rules, save formats, voxel models, or APK generation are included.
