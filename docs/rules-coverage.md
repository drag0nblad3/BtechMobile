# Rules coverage (Total Warfare)

Status: ✅ done + tested · 🟡 partial · ⬜ not started. Keep one line per rule.

## Turn sequence
- 🟡 Initiative: 2d6 per side, ties reroll, loser moves first — no initiative modifiers.
- 🟡 Unit alternation — `TODO(rules)`: unequal-numbers batching.
- ⬜ Weapon attack, physical attack, heat, end phases (stubs only).

## Ground movement ('Mechs)
- ✅ Walking / running MP (run = walk × 1.5 rounded up).
- ✅ Facing changes: 1 MP per hexside.
- ✅ Terrain costs: clear/pavement +0, rough +1, light woods +1, heavy woods +2.
- ✅ Level change: 1 MP per level, max 2 levels per hex.
- 🟡 Water: depth 1 +1, depth 2+ +3, no running into depth 1+ — `TODO(rules)`: verify
  level-change handling when entering/leaving water.
- ✅ Stacking: pass through friends, not enemies; one 'Mech per hex at end of movement.
- ⬜ Backward movement.
- ⬜ Jumping.
- ⬜ Standing up, going prone, minimum movement, lateral shift (optional rule).
- ⬜ Piloting skill rolls from movement (running in rough, skidding on pavement, etc.).

## Record sheets
- ✅ Internal structure by tonnage (standard structure).
- ✅ Armor per location, rear armor on torsos, maximum armor check.
- ✅ Critical slot layout: engine, gyro, cockpit, sensors, life support, actuators, equipment.
- 🟡 Heat sinks: single only; `TODO(rules)`: 10 engine-integral for every design.
- ⬜ Tonnage / construction validation (engine, armor and equipment weights).
- 🟡 Heat scale effects (MP, to-hit, shutdown, ammo explosion) — `TODO(rules)`: verify thresholds.

## Combat
- ⬜ Line of sight, to-hit modifiers, weapon attacks, damage, criticals, heat, physicals.
