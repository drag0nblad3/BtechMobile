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
- ✅ Standing up: 2 MP plus a piloting roll; failing means falling again. Impossible with a
  destroyed gyro or both legs gone.
- ⬜ Going prone voluntarily, minimum movement, lateral shift (optional rule).
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

## Critical hits
- ✅ Crit check when structure is damaged or on a hit-location roll of 2: 8-9 one, 10-11 two,
  12 three (head/limb blown off) — `TODO(rules)`: verify.
- ✅ Random hittable slot; empty slots don't count — `TODO(rules)`: no transfer when full.
- ✅ Engine (+5 heat/turn, 3 destroys), gyro (+3 PSR, 2 = fall, can't stand), cockpit (pilot
  killed), sensors (+2, 2 = can't fire), life support (pilot hit at 15+ heat), actuators,
  weapons, ammo (explodes), heat sinks.

## Piloting skill rolls and falls
- ✅ Owed rolls collected per phase and rolled at its end.
- ✅ Triggers: 20+ damage in a phase (+1), gyro hit, leg actuator hit, being kicked, missing
  a kick; automatic falls for destroyed gyro, leg blown off, shutdown.
- ✅ Lasting modifiers: gyro +3 each, destroyed leg +5, hip +2, other leg actuators +1.
- 🟡 Falls: ceil(tons/10) × (levels + 1) damage in 5s, random new facing, pilot roll to avoid
  a hit — `TODO(rules)`: fall direction table, falling from heights, leg destroyed by damage.

## Physical attacks
- ✅ Punch: piloting + movement mods, ceil(tons/10) damage, punch table; not with an arm that
  fired; no hand +1, missing/broken upper or lower arm +2 and half damage.
- ✅ Kick: piloting − 2, ceil(tons/5) damage, kick table, target rolls to stay up; a miss
  makes the kicker roll.
- ✅ Two punches or one kick per turn; adjacent target, front arc (punch: or that arm's side).
- 🟡 Level differences: only within 1 level — `TODO(rules)`: which table per level difference.
- ⬜ Charge, death from above, push, club, physical weapons.

## Pilots
- ✅ 6 hits kill; consciousness roll after each hit (3, 5, 7, 10, 11); wake-up roll in End Phase.

## Explanations (learning layer, not a rule)
- ✅ Every event has log text at three levels: Full (reasons for each number, each reason
  once per phase; phase intros once per battle), Light (numbers on one line), Off (outcomes).
- ✅ Advice: move preview (defense gained vs own penalty and heat, walk-vs-run, rear arcs),
  volley (expected damage, heat after the turn, which weapon to hold), best target,
  punch vs kick (including the chance of falling after a missed kick).

## Force building and play
- ✅ Two sides, up to 4 'Mechs each, tonnage budget (100-400 t); deploy on opposite edges.
- 🟡 Balance by tonnage only — `TODO(rules)`: Battle Value.
- ✅ Hot-seat play (both sides on one device). ⬜ Bot opponent.
- ✅ Terrain: clear, rough, rubble, light/heavy woods, pavement, water depth 1-2, hills.
