# BtechMobile planning

**Last updated:** 2026-11-20
**Status:** Prototype scaffold. Android is the primary target platform.

## 1. Current state

Before this document, the repository held only design notes: the
[mech sprite standard](graphics/mech-sprite-standard.md), which describes 2D mech
sprites in a 3D world with six hex-facing views plus a top-down view, and records the
provisionally approved Mad Dog / Vulture visual target. There was no code, engine or
build setup.

The repository now contains a Godot 4.5 project in `game/` that runs on Android:

| Piece | File | What it does |
| --- | --- | --- |
| Project settings | `game/project.godot` | Compatibility renderer, landscape, ETC2/ASTC textures, 1280×720 base size that stretches to any screen |
| Android export | `game/export_presets.cfg` | Debug-signed APK for arm64-v8a phones and x86_64 emulators |
| Prototype scene | `game/scenes/main.tscn`, `game/scripts/main.gd` | Hex board, three placeholder mechs, orbit camera, small HUD |
| Hex grid | `game/scripts/hex_grid.gd` | Flat-top axial coordinates, board mesh |
| Mech sprites | `game/scripts/directional_sprite.gd` | Picks one of six directional views from the camera bearing, or the top-down view above 65° camera elevation |
| Sprite loading | `game/scripts/mech_sprite_library.gd` | Loads `art/mechs/<chassis>/core/facing_NNN.png` and `top/top_000.png`, with generated placeholders when art is missing |
| Touch camera | `game/scripts/camera_rig.gd` | One-finger orbit, two-finger pinch zoom, mouse fallback on desktop |
| CI | `.github/workflows/android.yml` | Imports the project, runs the scene headless to catch script errors, exports a debug APK as a build artifact |

## 2. Android adaptation decisions

**Engine: Godot 4.5.** It is free and open source, exports to Android without extra
licensing, and its `Sprite3D` billboards map directly onto the sprite standard's
"2D sprites in a 3D world" design. Unity was the main alternative; it adds licensing and
a heavier editor workflow without a clear benefit for a sprite-based game.

**Renderer: Compatibility (OpenGL ES 3).** It runs on the widest range of Android
devices, including older and low-end phones. The game is mostly unlit sprites on a
simple board, so it doesn't need the Vulkan-based Mobile renderer's features. Revisit if
lighting or effects outgrow it.

**Orientation: sensor landscape.** A hex board and HUD fit a wide screen better. The
phone can still flip between the two landscape directions.

**Input: touch first.** The camera is driven by touch gestures, and mouse input works as
a fallback so the same scene is usable in the desktop editor. Mouse events that Godot
synthesizes from touches are ignored, so a drag is never handled twice.

**Textures: ETC2/ASTC import enabled.** Android export requires it, and it keeps sprite
atlases small in GPU memory.

**Architectures: arm64-v8a and x86_64.** arm64 covers current phones; x86_64 lets the
APK run on the Android emulator. 32-bit ARM is off to keep the APK small and can be
turned on in the export preset if older devices matter.

**Package id: `org.btechmobile.game`.** This is a placeholder. Pick the final id before
the first Play Store upload, because it can't change afterwards.

**Sprite conventions used in code** (these extend the sprite standard and should be
copied into it once confirmed):

- World north is -Z. Hex facing 0 points north, and facings advance clockwise seen from
  above, in 60° steps. Hexes are flat-topped, so each facing points at a hex side.
- Directional view `facing_000` is the camera directly in front of the mech;
  `facing_060` is the camera 60° clockwise around the mech from its front, and so on.
- The top-down sprite's forward axis is the top of the image.
- Directional sprites sit on the ground with their bottom edge at the mech's position.
- Placeholder art uses the approved palette zones: gray armor, charcoal panels, khaki
  accents, dark steel joints and teal cockpit glass.

## 3. Building for Android

### From CI (no local setup)

Push a branch or open a pull request. The **Android build** workflow produces a
`BtechMobile-debug-apk` artifact on the run page. Install it with
`adb install BtechMobile-debug.apk`, or copy it to the phone and open it.

### Locally

1. Install [Godot 4.5.1](https://godotengine.org/download) and its export templates
   (Editor › Manage Export Templates).
2. Install JDK 17 and the Android SDK (Android Studio is the simplest way), including
   platform-tools and build-tools.
3. In Godot, set Editor Settings › Export › Android: the Android SDK path, the Java SDK
   path, and a debug keystore (Godot can generate one).
4. Open `game/project.godot`, then Project › Export › Android › Export Project, or use
   the Remote Debug button to run directly on a USB-connected phone.

Command line equivalent, run from the repository root:

```sh
godot --headless --path game --import
godot --headless --path game --export-debug "Android" ../build/android/BtechMobile-debug.apk
```

## 4. Remaining work for Android

- **Test on real devices.** The scaffold has been checked in CI only. Try a recent
  phone, a low-end phone and a tablet, and note frame rate (shown in the HUD) and touch
  feel.
- **Release signing.** Create a release keystore, keep it out of git, and add it to CI
  as GitHub secrets (`GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER`, `_PASSWORD`).
- **Play Store format.** The Play Store requires an Android App Bundle (AAB), which needs
  Godot's Gradle build (`gradle_build/use_gradle_build=true` plus the Android build
  template). Set this up before the first store upload, along with target SDK checks.
- **Icons and splash.** Add adaptive launcher icons (foreground and background layers)
  and a boot splash. The current icon is a placeholder.
- **Safe areas.** Keep HUD controls clear of notches, cutouts and gesture bars using
  `DisplayServer.get_display_safe_area()`.
- **Lifecycle.** Pause the game and save state when the app is backgrounded
  (`NOTIFICATION_APPLICATION_PAUSED`), and decide what the Android back button does
  (right now it quits).
- **Performance budget.** Set targets (for example 60 fps on a mid-range phone, 30 fps
  minimum on low-end) and measure sprite atlas memory once real art exists.
- **Rights and licensing.** The sprite standard notes that using recognizable BattleTech
  designs needs a licensing decision before any public distribution, including the
  Play Store.

## 5. Roadmap

### Phase 0: Foundation (this change)
- Godot project, Android export, CI-built debug APK.
- Directional sprite system with placeholder art, hex board, touch camera.

### Phase 1: Sprite validation
Follows the "Validation / decisions to settle" list in the sprite standard.
- Import the Mad Dog prototype art at 0°, 15° and 25° elevations as
  `art/mechs/mad_dog/...` and compare them on a phone with the orbit camera.
- Tune the top-down switch threshold and decide whether view changes need a short
  cross-fade.
- Freeze the elevation; define the sprite manifest format (pivots, anchors, layers,
  damage states, atlas rectangles) and load it in `mech_sprite_library.gd`.
- Add palette swapping for faction colors with a shader that reads the color-zone
  masks.

### Phase 2: Core game loop
- Hex selection by tapping, movement with facing changes, terrain and elevation.
- Turn structure, a first weapon and damage model, and component damage sprites.
- Camera pan and focus-on-unit controls.

### Phase 3: Content and polish
- More chassis and modular variants, effects (smoke, fire, debris), sound, menus.
- Save and load, settings, tutorial.

### Phase 4: Release
- Licensing resolved, release signing, AAB build, store listing, closed testing track.

## 6. Open questions

1. Is the target audience phones, tablets, or both? This affects HUD scale and minimum
   device spec.
2. Single player only, or local or online multiplayer later?
3. What is the minimum Android version to support? Godot 4.5's default is Android 7
   (API 24).
4. What is the final app name and package id?
