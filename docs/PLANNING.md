# BtechMobile planning

**Last updated:** 2026-11-20
**Target:** Android phones, landscape. Godot 4.5, typed GDScript.

See `architecture.md` for how the code is layered and `rules-coverage.md` for
rule-by-rule status. This document tracks Android readiness and the overall roadmap.

## 1. Current state

First playable slice (PR #1): load a scenario, select a 'Mech, preview walk/run paths
with facing, and move; sides alternate by initiative. Rules live in `src/core`
(pure `RefCounted`, unit-tested headless), presentation in `src/view`, content as JSON
in `data/`. CI (`ci.yml`) runs the unit tests and a headless smoke run on every push.

Combat, heat, physicals, jumping and backward movement are not started. Units are
placeholder box 'Mechs; the 2D sprite direction in `graphics/mech-sprite-standard.md`
is approved as a visual target but not yet wired in.

## 2. Android readiness

### Already in place (PR #1)
- Landscape orientation that follows the sensor (`window/handheld/orientation=4`).
- Mobile renderer, ETC2/ASTC texture import, 1280×720 base size stretched to any screen.
- Touch-first input: pan, pinch zoom, twist to orbit, two-finger tilt, tap and
  double-tap; mouse events synthesized from touch are ignored, so nothing fires twice.
- Phone-sized HUD buttons (150×72) and large outlined text.
- No C#, which is still experimental on Android.

### Added in this change
- **Android export preset** (`export_presets.cfg`): debug-signed APK for arm64-v8a
  phones and x86_64 emulators, immersive full screen. It explicitly includes
  `data/*.json` (loaded at runtime with `FileAccess`/`DirAccess`) and leaves `tests/`,
  `tools/` and `docs/` out of the package. `export_presets.cfg` was in `.gitignore`;
  it is now tracked, since Godot 4 keeps keystore passwords in
  `.godot/export_credentials.cfg`, which stays ignored.
- **Safe-area margins** in `BattleHud`: on phones, HUD controls are pushed clear of
  notches, camera cutouts and gesture bars using `DisplayServer.get_display_safe_area()`.
  No change on desktop.
- **Manual APK workflow** (`.github/workflows/android.yml`): builds a debug APK and
  attaches it to the run. It runs only when started by hand from the Actions tab,
  never on push or pull request.

### Not yet verified
None of the Android pieces have been run yet: the export has not been tried, and
the game hasn't been played on a device. The first manual run of the APK workflow and a
session on a real phone are the next checks.

### Remaining Android work
- **Device testing.** One recent phone, one low-end phone, one tablet. Watch frame rate
  with a whole map on screen, touch feel, and text size.
- **Renderer fallback.** The Mobile renderer needs Vulkan. Godot 4.5 falls back to
  OpenGL ES 3 on devices without it (`rendering_device/fallback_to_opengl3`, on by
  default), but `terrain.gdshader` should be checked under that fallback, or the
  project switched to the Compatibility renderer if low-end support matters more
  than visuals.
- **App lifecycle.** Pause and autosave on `NOTIFICATION_APPLICATION_PAUSED`; decide what
  the back button does (today it quits immediately). Save/load is a prerequisite.
- **Release signing.** Create a release keystore kept out of git; store it as GitHub
  secrets (`GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER`, `_PASSWORD`).
- **Play Store build.** The store needs an Android App Bundle (AAB), which requires
  Godot's Gradle build (`gradle_build/use_gradle_build=true` plus the Android build
  template). Set up before the first store upload.
- **Identity.** `org.btechmobile.game` is a placeholder package id; it can't change
  after the first store upload. Adaptive launcher icon and splash are still to do.
- **Performance budget.** Set targets (e.g. 60 fps mid-range, 30 fps floor on low-end)
  and measure once real 'Mech art and effects exist.
- **Licensing.** Recognizable BattleTech names and designs need a rights decision
  before any public release, Play Store included.

## 3. Roadmap

Follows the module order in `architecture.md`, with Android milestones slotted in.

1. **Android baseline (now).** Export preset, safe areas, first APK on a real phone.
2. **Movement complete.** Backward walking, jumping, prone/standing, minimum movement,
   movement piloting rolls.
3. **Line of sight and to-hit.** `Hex.line` with woods and levels; to-hit modifiers,
   with an on-screen LOS/to-hit preview sized for touch.
4. **Unit data.** Armor, internal structure, weapons, heat sinks; import from MegaMek
   MTF/BLK.
5. **Weapon attacks and damage.** Hit locations, damage transfer, criticals, ammo
   explosions; an attack-declaration UI that works one-handed on a phone.
6. **Physicals, heat, piloting rolls, falls.**
7. **Mech graphics.** Replace `PlaceholderMech` through `UnitView.set_model()` with the
   sprite system from `graphics/mech-sprite-standard.md` (Mad Dog first); validate
   camera elevation on a phone.
8. **Bot opponent, save/load, app lifecycle.** Autosave on pause depends on save/load.
9. **Release prep.** Licensing decision, release signing, AAB, icon, store listing,
   closed testing track.
10. **Campaign layer** (`src/campaign/`).

## 4. Open questions

1. Phones only, or tablets too? This affects HUD scale and the minimum device spec.
2. Minimum Android version? Godot 4.5's export default is the floor unless set lower.
3. Mobile renderer with OpenGL fallback, or Compatibility renderer everywhere?
4. Final app name and package id.
5. Local hot-seat or online multiplayer later, or single player against the bot only?
