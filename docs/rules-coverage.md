# Rules coverage (Total Warfare)

Status: ✅ done + tested · 🟡 partial · ⬜ not started. Keep one line per rule.

## Turn sequence
- 🟡 Initiative: 2d6 per side, ties reroll, loser moves first — no initiative modifiers.
- ✅ Unit alternation with unequal numbers (`UnequalNumbers`, p. 41): the bigger side spreads its 'Mechs over the smaller side's turns, extra ones first; recounted each phase.
- ✅ Phases: Initiative → Movement → Weapon Attack → Physical Attack → Heat → End.
- ✅ Attacks declared unit by unit in initiative order, resolved together at phase end
  (a 'Mech destroyed this phase still fires).
- ✅ Game ends when one side (or none) has 'Mechs left.

## Ground movement ('Mechs)
- ✅ Walking / running MP (run = walk × 1.5 rounded up); -1 walk MP per leg actuator hit (hip, upper, lower, foot), 1 with a leg gone, 0 with both.
- ✅ Facing changes: 1 MP per hexside.
- ✅ Terrain costs: clear/pavement +0, rough +1, light woods +1, heavy woods +2.
- ✅ Level change: 1 MP per level, max 2 levels per hex.
- ✅ Water (p. 47): depth 1 +1, depth 2+ +2, plus the level change to the bottom; running in is allowed but costs a piloting roll.
- ✅ Hip hit or destroyed leg: 1 level per hex forward, none backward.
- ✅ Stacking: pass through friends, not enemies; one 'Mech per hex at end of movement.
- ✅ Backward walking (not running), same costs, at most 1 level change; any backward level change costs a piloting roll, and a failure falls (in the lower hex).
- 🟡 Jumping (p. 50): 1 MP per hex, any landing facing, ignores terrain costs; no hex higher than start level + jump MP (woods don't count, buildings do); from water the start is the bottom, depth 2+ can't jump, leg jets don't fire in depth 1; landing in water costs a roll; heat 1/hex (min 3); +3 own, +1 extra to be hit — `TODO(rules)`: landing on building roofs.
- ✅ Standing up: 2 MP plus a piloting roll (-1 helps it); failing means falling again; standing frees the facing. Impossible with a
  destroyed gyro or both legs gone.
- 🟡 Going prone instead of moving (heat as walking) — `TODO(rules)`: TW allows moving first, then dropping for 1 MP.
- ✅ Minimum movement (p. 49): running, one hex straight ahead for all MP, even if it costs more.
- ✅ Movement piloting rolls (`MovePsr`): rolled the moment the hex is entered for running into water, rubble, backward level changes and landing in water (a failure ends the move with a fall); rolled after the move for running 1+ hex with a gyro/hip hit or leg gone, and jumping with gyro, leg or leg actuator damage.
- ⬜ Skidding: not in the Core Rulebook; `Skid` is kept for an optional rule but never used.
- ⬜ Lateral shift (optional rule).

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
- ✅ Firing while prone (`ProneFire`, p. 67): needs an arm; the propping arm (picked automatically: the one with less firepower) and leg weapons can't fire.
- ✅ Prone target (-2 adjacent, +1 otherwise); immobile target -4 (shut down, unconscious or 0 walking MP); secondary target +1 in any arc, and the primary must be in the forward arc if any target is (p. 64).
- ✅ Partial cover from depth 1 water: +1, leg hits absorbed.
- ✅ Firing arcs (p. 60): forward 120°, sides 60°, rear 120°; arms add their side; rear mounts fire rear. Hit zones (p. 73) keep the hexside shape: front is 3 hexsides.
- ✅ Torso twist one hexside in the weapon phase; leg weapons keep the legs' facing; punches use the torso.
- ✅ Target number 2 or less always hits (p. 72); target > 12 can't be attempted.
- ✅ Cluster hits table; LRMs in 5-point groups, SRMs per missile.
- ✅ Ammo used per shot; no ammo, no shot.
- ✅ Flamers (p. 183): a hit deals damage and the same amount of heat to the target; outside heat is capped at 15 per turn.
- 🟡 Indirect LRM fire (`IndirectFire`, pp. 62, 70): a friendly 'Mech with line of sight spots one target per turn; +1 indirect, + spotter's movement, +1 if the spotter also attacks (and +1 to the spotter's own attacks); terrain counted from the spotter — `TODO(rules)`: a spotter may still charge or DFA.
- ⬜ Called shots, aimed shots.

## Damage
- ✅ Hit location tables (front/rear, left, right) — `TODO(rules)`: verify.
- ✅ Armor → structure → transfer inward; rear armor on torsos.
- ✅ Side torso destroyed takes its arm; head or CT destroyed destroys the 'Mech.
- ✅ Ammo explosion (pp. 95-96): remaining shots × damage, capped at 20, into structure, transferring structure-to-structure; over the cap the surviving last location loses its armor (rear for a torso); MechWarrior takes 1 hit.
- ✅ Head hits (p. 117): every hit that damages the head is 1 MechWarrior hit, even if the armor holds.
- ✅ 20-damage piloting roll counts the armor and structure pips actually marked off, including falls and explosions.

## Heat
- ✅ Heat from walking (1), running (2), weapons fired, engine hits (5 each).
- ✅ Dissipation 1 per working heat sink.
- ✅ Shutdown (`HeatShutdown`, pp. 104-105): roll at 14+ (4+, 6+, 8+, 10+, auto at 30 or with an unconscious warrior), resolved before ammo; a shut-down 'Mech doesn't fall but can't act, fails piloting rolls and gets no engine-hit heat.
- ✅ Restart: automatic below 14 (even unconscious); otherwise a conscious warrior rolls the same number; never at 30+.
- ✅ Ammo explosion roll at 19+ (4+, 6+, 8+); the bin with the most damage per shot cooks off, ties to the most shots left.
- ✅ Water cooling (p. 103): submerged heat sinks cool double, max +6; standing in depth 1 only leg sinks are under.
- ✅ Outside heat (flamers) capped at 15 per turn.
- ✅ Life support hit: 1 MechWarrior hit per Heat Phase at heat 10-19, 2 at 20+; 1 in the End Phase when fully under water.
- ✅ Jumping heat (1 per hex, min 3).

## Critical hits
- ✅ Crit check when structure is damaged or on a hit-location roll of 2: 8-9 one, 10-11 two,
  12 three (head/limb blown off) — `TODO(rules)`: verify.
- ✅ Random hittable slot; empty slots don't count. A location that started the phase with nothing left to hit passes criticals inward; otherwise extras are lost (p. 95).
- ✅ A location destroyed by damage still rolls; only hits on ammo count (p. 87).
- ✅ Engine (+5 heat/turn, 3 destroys), gyro (+2 PSR, 2 = fall, can't stand), cockpit (pilot
  killed), sensors (+2, 2 = can't fire), life support (see Heat), actuators,
  weapons, ammo (explodes), heat sinks.

## Piloting skill rolls and falls
- ✅ Owed rolls collected per phase and rolled at its end.
- ✅ Triggers: 20+ damage in a phase (+1), gyro hit, leg actuator hit, being kicked, missing
  a kick; automatic falls for destroyed gyro and leg blown off; a shut-down 'Mech fails any roll.
- ✅ Lasting modifiers: gyro +2, destroyed leg +4 (replaces that leg's actuators), hip/upper/lower leg actuators +1 each; positive mods of other rolls owed in the same phase add on; one roll per leg for actuator hits; an immobile 'Mech falls automatically.
- ✅ Falls (p. 115): facing unchanged; 1D6 = 1 hits the rear, else the front; ceil(tons/10) × (levels + 1) in 5s, halved in depth 1+ water.
- ✅ Seatbelt check (p. 117): piloting + 1 per level fallen, nothing else; immobile or over 12 is an automatic hit.
- 🟡 Consciousness (p. 117): one roll after the phase's damage, PSRs and falls, against the current hit total; wake-up rolls in later End Phases only — `TODO(rules)`: Movement Phase rolls should be immediate.

## Physical attacks
- ✅ Punch: piloting + movement mods, ceil(tons/10) damage, punch table; not with an arm that
  fired; no hand +1, missing/broken upper or lower arm +2 and half damage.
- ✅ Kick: piloting − 2, ceil(tons/5) damage, kick table, target rolls to stay up; a miss
  makes the kicker roll.
- ✅ Two punches or one kick per turn; adjacent target, front arc (punch: or that arm's side).
- 🟡 Level differences: only within 1 level — `TODO(rules)`: which table per level difference.
- 🟡 Charge: declared with a walk/run move ending next to an enemy straight ahead; piloting +
  piloting difference + target movement/terrain; ceil(tons/10) × hexes to the target,
  ceil(target tons/10) back; both roll at +2; target shoved, attacker follows. No weapon fire.
- 🟡 Death from above: same with a jump; ceil(tons/10) × 3 (punch table), ceil(tons/5) to own
  legs, attacker rolls at +4, a miss is an automatic fall.
- ✅ Push: piloting − 1, target straight ahead, no damage, shoved one hex and must roll.
- ✅ Displacement (pp. 113-114): domino effect (roll to step forward/back, else pushed on and falls; crushed with nowhere to go), off the map destroys, 2+ levels down is a fall, 3+ up can't happen.
- 🟡 `TODO(rules)`: charge/DFA to-hit modifiers and where a missed attacker ends up (physical attacks PR).
- ⬜ Clubs, physical weapons.

## Buildings
- ✅ Classes light/medium/heavy/hardened (CF 15/40/90/120), +1/+2/+3/+4 MP to enter, height in levels.
- 🟡 Entering: a 'Mech heavier than the remaining CF collapses it and stops there; otherwise a
  piloting roll (+0/+1/+2/+5), failure = CF/10 damage — `TODO(rules)`: verify both.
- 🟡 Hits on a 'Mech inside: walls soak CF/10, building takes the whole hit — `TODO(rules)`.
- 🟡 Collapse: hex becomes rubble, the 'Mech inside falls from the roof height — `TODO(rules)`.
- ✅ Buildings block line of sight like a hill as tall as the roof.
- 🟡 Shooting buildings (`BuildingFire`): tap a building in the weapon phase; -4 to hit, each hit lowers CF, 0 CF collapses it — `TODO(rules)`: verify -4, no secondary-target cost, 'Mechs inside unhurt until collapse.
- ⬜ Physical attacks on buildings, standing on roofs, jumping onto buildings, charges and
  displacement into buildings, basements.

## Pilots
- ✅ 6 hits kill; consciousness numbers 3, 5, 7, 10, 11 (timing under Piloting skill rolls and falls).

## Explanations (learning layer, not a rule)
- ✅ Every event has log text at three levels: Full (reasons for each number, each reason
  once per phase; phase intros once per battle), Light (numbers on one line), Off (outcomes).
- ✅ Advice: move preview (defense gained vs own penalty and heat, walk-vs-run, rear arcs),
  volley (expected damage, heat after the turn, which weapon to hold), best target,
  punch vs kick (including the chance of falling after a missed kick).
- ✅ Training battle (`Tutorial`, `LessonCard`): Wolverine vs a computer Commando with
  lesson cards on first movement, fire, hits, heat, piloting rolls and the end.

## Force building and play
- ✅ Two sides, up to 4 'Mechs each, Battle Value budget (2000-8000); deploy on opposite edges.
- 🟡 Battle Value (`BattleValue`, `BvText` explains it) — `TODO(rules)`: simplified BV 2 (rear weapons half, 15 per ton of ammo, no CASE, no pilot-skill multiplier).
- ✅ Hot-seat play, or either side played by the computer (`Bot`): it scores every reachable
  end hex by expected damage dealt vs taken plus heat, picks the best target and holds weapons
  to stay cool, punches/kicks when worth the fall risk, and logs why (when explanations are on).
- ⬜ Bot charges, DFAs and pushes; smarter focus fire and retreat.
- ✅ Terrain: clear, rough, rubble, light/heavy woods, pavement, water depth 1-2, hills.
- ✅ Maps: Test Valley, River Crossing, Rolling Hills, Dense Forest, City Outskirts.
- ✅ Tapping an empty hex explains its movement cost, cover and cooling.
- ⬜ Buildings, bridges as structures, fire and smoke.
