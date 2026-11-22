# Experience polish: responsive actions, safe pause, and camera gestures

**Status:** Feature branch. CI and Android device verification are pending.

## Changes

- The bottom movement bar keeps mode, facing, Cancel and Confirm always
  accessible. Less-used, eligibility-gated actions (Prone, Charge/DFA,
  Smash in, MASC, Supercharger and Leave map) open from **Actions**.
  Their rule handlers and labels are unchanged.
- **Pause** or Escape opens a full-screen overlay and stops scene processing;
  Resume, Save, or Save & Exit are available. Save & Exit refuses to leave
  if saving fails. Android Back opens/closes the pause overlay.
- Disable automatic Android Back exit in project settings, with deliberate
  Back behavior in menu (quit), replay and forensics (return to menu).
- Ignore tilt during pinch and twist updates to avoid unwanted camera pitch,
  while preserving controlled two-finger vertical dragging.

## Architecture

Only view code and Android configuration are affected. Combat RNG,
GameState, BattleSave formats, animations and voxel models are unchanged.

## Validation checklist

- `godot --headless --import`
- `godot --headless -s tests/run_tests.gd -- experience_polish`
- `godot --headless -s tests/run_tests.gd`
- `godot --headless -s tools/ui_smoke.gd`
- Phone: open Actions for normal moves, prone, MASC and charge. Test save,
  resume, failed save and Android Back; check rotation, zoom, and tilt gestures.
- Do not generate an APK unless specifically requested.
