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

## Battlefield visual polish — November 22, 2026

- **Terrain:** softened elevation luminance to preserve map palette, added
  shader-based inset hex rims for depth/grid definition with no extra draw
  calls, and dark steel underlay for gaps. Ground props remain MultiMesh.
- **Water:** shared GPU ripple shader, subtle emissive glints and a 0.77-alpha
  surface without per-hex CPU animation.
- **Weather/light:** day, night, rain, snow and low visibility now choose
  different sky/sun palettes. Non-volumetric distance fog only appears in
  relevant conditions; one shadow-casting directional light.
- **Action focus:** amber selection and red target rings track actual unit
  views, do not fill/obscure a hex, and disappear with hidden units.
- **Attack feedback:** low-poly colored energy beams and moving missile/AC
  tracers; visual misses pass beside a model. Hit explosions still use the
  existing voxel blast. Bounded, fading damage numbers make impacts easier
  to read. Tracer nodes cap at 30 concurrent and damage labels at 18.
- **Battle HUD:** turn-side accent line; tighter nonessential shortcuts;
  tactical-link strip and translucent explanatory panel collapse completely
  when their text is empty. No controls removed and no combat logic changed.

### Validation

Run CI including `test_battle_visuals.gd`, the default and city UI smoke,
plus a single 1280x720 software-rendered battlefield preview on this PR.
Check final contrast and readability on a real Android landscape screen,
particularly text in dense terrain and through fog; there is **no** APK build.
