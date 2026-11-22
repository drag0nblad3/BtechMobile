# Tactical Academy — battle forensics and cinematic camera

**Status:** first implementation on the cinematic-academy feature branch.

## Gameplay: cinematic camera toggle (implemented first)

The battle HUD has a **Cine: Off / Cine: On** toggle. The initial default is Off (the existing tactical camera). Choosing On persists to the existing `user://settings.cfg` game preferences and survives battle restarts.

A small presentation-only director follows moving units and makes temporary orbit, angle, and zoom changes for weapon attacks, physical attacks, falls, ammo explosions, and destroyed units. Camera pans, pinches, twists, tilts, tapping a unit, or toggling top-down view immediately take control for a short time. The next actual battle action may re-enable automatic framing. Switching cinematic Off restores the camera pose from before the toggle.

The camera does **not** pause the battle, slow down turns, change hit chances, reroll dice, block interactions, or become part of authoritative saved game state. This is *live action-directed framing*, not a pre-rendered cutscene system. Visual effects still run at their existing timing; a busy attack phase can produce a queue of at most four camera shots. It needs on-device performance and usability testing.

## Tactical Academy: battle forensics

Where to open it:
- At battle end, choose **Analyze Battle**.
- In a saved battle replay, choose **Forensics**.
- From the force builder, choose **Tactical Academy: Forensics** when a last-battle replay exists.

The scene shows:
1. **Attack accuracy:** hits and attempts from actual WEAPON_FIRED and PHYSICAL GameEvents, alongside expected hits summed from exact 2d6 probabilities at each recorded target number. A weapon without ammunition does not count as a fired attack. Expected hits are a statistical baseline, not a prediction of victory.
2. **Recorded damage:** positive DAMAGE events, credited to the source unit when the source ID identifies one, and counted as incoming damage for the target. This is *logged damage*, not necessarily net lost armor/structure due to transfer or special protections.
3. **Unit performance:** hits, attempts, probability baseline, damage dealt/received, peak reported heat, critical-hit events and failed PSRs.
4. **Decisive-event markers:** destroyed units, ammo explosions, heavy damage, falls, dangerous heat, failed PSRs, unexpected misses, and improbable hits.
5. **Full event ledger:** explanatory event text grouped by turn, with inspectable links.

Selecting an item and pressing **Inspect in replay** opens the read-only replay at the nearest recorded checkpoint. Events not stored as their own state snapshot jump to the next snapshot; this may show other intervening resolution events. The forensic reports do not re-run the combat simulation.

## Data boundary

`BattleRecorder.record` now attaches a small codec-packed `events` array to each checkpoint. Events that already have a state snapshot appear in that checkpoint; other events attach to the most recent checkpoint. The `BattleForensics` analyzer only extracts scalar recorded facts (hit, roll, to-hit target, unit IDs, heat and damage). It doesn't instantiate units or reroll combat to calculate its measurements. Full replay frames and ledger remain stored together in `last_battle_replay.zst`, so no save schema bump is required.

Legacy replay files without event ledgers still open. Their numerical forensic summary says it lacks telemetry instead of inventing statistics.

## Next Academy iterations

A later pass can identify decision quality using legal alternative moves/attacks and reproducible branching from a full RNG-inclusive checkpoint. This first forensic pass **does not** claim which untried decision would have been better.

## Validation

Run:

    godot --headless --import
    godot --headless -s tests/run_tests.gd -- battle_forensics
    godot --headless -s tools/academy_smoke.gd

Also verify the cinematic button stays usable on 1280×720 landscape screens and small Android phones; test with several simultaneous attack animations and with manual camera gestures. No APK is built by the feature branch.
