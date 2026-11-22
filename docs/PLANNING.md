# BtechMobile planning

**Last updated:** 2026-11-22
**Target:** Android phones, landscape. Godot 4.5, typed GDScript.

See `architecture.md` for how the code is layered and `rules-coverage.md` for
rule-by-rule status. This document tracks Android readiness and the overall roadmap.

## 1. Current state

First playable slice (PR #1): load a scenario, select a 'Mech, preview walk/run paths
with facing, and move; sides alternate by initiative. Rules live in `src/core`
(pure `RefCounted`, unit-tested headless), presentation in `src/view`, content as JSON
in `data/`. CI (`ci.yml`) runs the unit tests and a headless smoke run on every push.

First playable milestone (stacked PRs after #3): a force builder (two lances under a
tonnage budget, two maps), the full turn (initiative, movement, weapon and physical
attacks, heat, end), line of sight, to-hit with named modifiers, cluster missiles,
damage transfer, critical hits, ammo explosions, piloting rolls and falls, punches and
kicks, live record sheets, a combat log, and explanations at Full / Light / Off with
advice on moves, volleys, targets and punch-vs-kick. Five 'Mechs: Jenner, Hunchback,
Wolverine, Catapult, Atlas. Play is hot-seat (both sides on one device).

Jumping, backward movement, torso twist, charges and death-from-above are not started.
'Mechs are placeholder boxes until sprite sets land; `SpriteMech` already loads them
(`graphics/sprite-integration.md`).

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

### Battle persistence (2026-11-21 feature branch)

- Versioned, compressed complete `GameState` save, including declared attacks, map state, objectives, pilot/critical details, and exact PRNG continuation.
- Save button, one autosave at the first active side of each turn, and pause autosave. Continue button in the force builder.
- Independent last-battle replay archive and read-only frame-by-frame viewer; recordings cover significant game events, not animation frames.
- Round-trip and RNG tests, plus battle save/resume/replay scene smoke, **passed Godot CI**. Android device testing remains pending. A save slot and replay archive may grow on long battles; next optimize snapshot deltas and storage quotas. See `docs/battle-save-replay.md`.

### Cinematic gameplay and Tactical Academy (2026-11-21 stacked PR #171)

- A persistent **Cine: On/Off** battle-HUD camera toggle reframes movement, weapon fire, physical attacks, falls and destruction; manual gestures take priority. Purely cosmetic, no effect on dice or turn progression.
- A compact per-event replay ledger powers Tactical Academy Battle Forensics: hit rates versus exact 2d6 expected hits, damage attribution, heat, piloting failures and decisive events, with replay checkpoints for inspection.
- Available at game over, from a replay, and from the force builder. Godot focused unit and scene-navigation tests passed on the feature branch; full-suite and Android on-device usability checks are still required. See `docs/tactical-academy.md`.

### Experience polish (2026-11-22 feature branch)

- The movement bar keeps mode, turn, Cancel and Confirm visible. Contextual
  actions are available through "Actions" without overflowing a phone screen.
- Pause, Save and Save & Exit are available in battle; Android Back opens
  the pause overlay instead of immediately quitting a running game.
- Pinch and twist gestures no longer simultaneously tilt the camera.
- Headless CI and on-device validation remain to be done. See
  `docs/experience-polish.md`.

### Tactical UI art direction (2026-11-22 stacked feature branch)

- A shared `UiSkin` palette and button/panel styles introduce a restrained
  field-command aesthetic with dark slate, cyan information and amber
  primary actions across launcher, force builder, battle, and analysis.
- No new heavy assets or external fonts; all interface visuals remain native
  Godot controls suitable for Android.
- Visual and touchscreen verification required (see `docs/ui-visual-polish.md`).

### Remaining Android work
- **Device testing.** One recent phone, one low-end phone, one tablet. Watch frame rate
  with a whole map on screen, touch feel, and text size.
- **Renderer fallback.** The Mobile renderer needs Vulkan. Godot 4.5 falls back to
  OpenGL ES 3 on devices without it (`rendering_device/fallback_to_opengl3`, on by
  default), but `terrain.gdshader` should be checked under that fallback, or the
  project switched to the Compatibility renderer if low-end support matters more
  than visuals.
- **App lifecycle.** Pause autosave and a Back-driven battle pause menu are implemented; verify on Android and restore UI selections/tutorial-card progress if needed.
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
2. **First playable milestone (done, in review).** Record sheets, weapons, to-hit, damage,
   criticals, heat, piloting rolls, punches and kicks, force builder, explanations.
3. **Movement complete.** Backward walking, jumping, torso twist, minimum movement,
   movement piloting rolls (running in rough, etc.).
4. **More rules.** Charge, death from above, push, clubs; Battle Value balancing;
   more 'Mechs and maps.
5. **Mech graphics.** Drop sprite sets into `assets/mechs/` (`SpriteMech` loads them);
   validate camera elevation on a phone; faction recolor and damage states.
6. **Bot opponent, save/load, replay, app lifecycle.** AI and snapshot saves/replays implemented; verify on phones, optimize snapshot storage and finish Back-button behavior.
7. **Release prep.** Licensing decision, release signing, AAB, icon, store listing,
   closed testing track.
8. **Campaign layer** (`src/campaign/`).

## 4. Rules assumptions to verify

No rulebook is in the repo, so the rules come from general knowledge of classic
BattleTech (Total Warfare, Standard level). Every uncertain point is marked
`TODO(rules)` in code and listed in `rules-coverage.md`. The ones most worth checking
against the book first:

1. Firing-arc and attack-direction boundaries (front = three forward hexsides).
2. Line of sight follows the book's LOS-level rules; divided LOS always picks the side
   worse for the attacker (the defender's choice).
3. Hit location, cluster, critical-hit and punch/kick tables.
4. Heat scale thresholds, shutdown restart timing, which ammo bin explodes.
5. Fall direction, fall pilot-damage roll, leg-loss movement.
6. Unequal unit counts in alternating movement.
7. Battle Value: simplified BV 2 (rear weapons half, flat ammo penalty, no CASE;
   pilot skill multiplier applied). Our numbers land within about 10% of published values.
8. Buildings follow the Core Rulebook's Threshold / Destroy Check system; careful
   entry, roofs and building fires are not modeled yet.
9. 'Mech designs (70 Inner Sphere designs plus 46 Clan designs (40 OmniMech configurations of 22 chassis, and six second-line 'Mechs: Hunchback, Phoenix Hawk, Rifleman, Warhammer and Marauder IIC, and the Kodiak)
   in `data/units/`) are written from general knowledge; the Clan loadouts are adapted to our
   whole-ton ammo and slot rules, so some differ from the readouts: check armor
   split, slot placement and ammo locations against the technical readouts. The Core
   Rulebook has no designs or construction rules. Weapon tons, slots and ranges match its
   weapon tables; every design must add up to its tonnage (`DesignWeight`, engine weights
   in `data/construction.json`), so 12 older designs had armor trimmed to fit.

## 5. Open questions

1. Phones only, or tablets too? This affects HUD scale and the minimum device spec.
2. Minimum Android version? Godot 4.5's export default is the floor unless set lower.
3. Mobile renderer with OpenGL fallback, or Compatibility renderer everywhere?
4. Final app name and package id.
5. Local hot-seat or online multiplayer later, or single player against the bot only?
