# Rules coverage (Total Warfare)

Status: ✅ done + tested · 🟡 partial · ⬜ not started. Keep one line per rule.

## Turn sequence
- 🟡 Initiative: 2d6 per side, ties reroll, loser moves first — no initiative modifiers.
- 🟡 Unit alternation — `TODO(rules)`: unequal-numbers batching.
- ✅ Phases: Initiative → Movement → Weapon Attack → Physical Attack → Heat → End.
- ✅ Attacks declared unit by unit in initiative order, resolved together at phase end
  (a 'Mech destroyed this phase still fires).
- ✅ Game ends when one side (or none) has 'Mechs left.

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

## Line of sight
- 🟡 Hills block if higher than both units; woods count if at least as high as both;
  3+ intervening woods points block — `TODO(rules)`: simplified, verify.
- 🟡 Divided LOS (exactly along hexsides) picks one side — `TODO(rules)`.
- 🟡 Units in depth 2+ water (or prone in depth 1) can't be seen — `TODO(rules)`: underwater combat.

## Weapon attacks
- ✅ To-hit: gunnery + attacker movement (walk +1, run +2) + target movement
  (3-4 +1, 5-6 +2, 7-9 +3, 10-17 +4, 18-24 +5, 25+ +6) + range (+0/+2/+4) + minimum range.
- ✅ Woods: intervening +1 light / +2 heavy, target hex the same.
- ✅ Heat to-hit (+1 at 8, +2 at 13, +3 at 17, +4 at 24); sensor hits +2 each; prone attacker +2.
- ✅ Prone target (-2 adjacent, +1 otherwise); immobile target -4; secondary target +1 front / +2 other.
- ✅ Partial cover from depth 1 water: +1, leg hits absorbed.
- 🟡 Firing arcs: front = 3 forward hexsides; arms add their side; rear mounts fire rear
  — `TODO(rules)`: verify arc boundaries; torso twist not implemented.
- ✅ Natural 2 always misses; target > 12 can't be attempted.
- ✅ Cluster hits table; LRMs in 5-point groups, SRMs per missile.
- ✅ Ammo used per shot; no ammo, no shot.
- ⬜ Flamers, indirect LRM fire, called shots, aimed shots.

## Damage
- ✅ Hit location tables (front/rear, left, right) — `TODO(rules)`: verify.
- ✅ Armor → structure → transfer inward; rear armor on torsos.
- ✅ Side torso destroyed takes its arm; head or CT destroyed destroys the 'Mech.
- ✅ Ammo explosion: remaining shots × damage into structure, pilot takes 2 hits.

## Heat
- ✅ Heat from walking (1), running (2), weapons fired, engine hits (5 each).
- ✅ Dissipation 1 per working heat sink.
- ✅ Shutdown roll at 14+ (4+, 6+, 8+, 10+, auto at 30); shut-down 'Mechs fall and can't act.
- 🟡 Restart: automatic below 14, else same roll — `TODO(rules)`: verify timing.
- 🟡 Ammo explosion roll at 19+ (4+, 6+, 8+) — `TODO(rules)`: which bin explodes.
- ⬜ Water cooling, jumping heat.

## Pilots
- ✅ 6 hits kill; consciousness roll after each hit (3, 5, 7, 10, 11); wake-up roll in End Phase.
