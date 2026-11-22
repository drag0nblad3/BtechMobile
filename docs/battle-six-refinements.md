# Six ordered battle refinements (2026-11-22)

This branch implements the six requested improvements in six consecutive commits.

1. **Model-aware weapon fire.** Use authored `muzzle` or `weapon_N` Node3D sockets when available, otherwise derive the shot origin from the model's actual bounds and orientation. Hits terminate at the target model surface. Add short localized impact sparks and restrained recoil. Future chassis-specific authored sockets will improve exact accuracy; fallback bounds are not a substitute for manual weapon attachment authoring.
2. **Continuous battlefield and real shorelines.** Tighten visible hex seams. Generate foam strips only where a water hex borders land or the map edge; do not add foam between neighboring water tiles. Water surface animation remains shader-driven.
3. **Surface-responsive movement.** Trigger a short, low-particle footfall at each completed movement translation, with a splash on water and dust on dry ground. These are presentation-only and never change movement MP or the rules.
4. **Tactical preview.** A movement path progresses visually from pale blue to yellow at the destination. The status line now previews MP spent and approximate movement heat alongside current heat. This is a preview, not the heat-phase rules calculation; terrain and equipment may change actual heat.
5. **Mobile HUD space.** Keep the frequent Pause, Log, Sheet, Explain, and Cinematic controls in the top row; group Save, Replay, Map View and Forensics under More. The phase tracker and existing action bars are preserved.
6. **Cinematic restraint.** Ignore routine misses and dry fire, shorten action holds, and return to the tactical pose after a shot. Once a player gestures, do not automatically take control again until they re-enable cinematic mode.

## QA
CI must pass Godot import, unit tests, battle visual smoke, launcher and battle UI smoke. Review 1280×720 Compatibility-renderer screenshots and test gestures and GPU cost on real Android devices before considering this fully polished. No APK built.
