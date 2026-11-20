# Rules coverage (Total Warfare)

Status: ✅ done + tested · 🟡 partial · ⬜ not started. Keep one line per rule.

## Turn sequence
- ✅ Initiative (p. 39): 2d6 per side, ties reroll with the same modifiers, loser moves first; totals may pass 2 or 12.
- ✅ Initiative Die (optional, `InitiativeDie`, toggled on the start screen): the loser gets +1 per loss in a row (max +6) until it wins.
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
- ✅ Jumping (p. 50): 1 MP per hex, any landing facing, ignores terrain costs; no hex higher than start level + jump MP (woods don't count, buildings do); from water the start is the bottom, depth 2+ can't jump, leg jets don't fire in depth 1; landing in water costs a roll; heat 1/hex (min 3); +3 own, +1 extra to be hit; 'Mech-scale buildings are landed on, on the roof.
- ✅ Standing up: 2 MP plus a piloting roll (-1 helps it); failing means falling again; standing frees the facing. Impossible with a
  destroyed gyro or both legs gone.
- ✅ Dropping prone (`ProneMoves`, p. 51): in place, or at the end of a walk/run with 1 MP to spare (the Prone button uses the previewed move); not after jumping.
- 🟡 Prone 'Mech that can't stand (destroyed gyro, both legs gone) only turns in its hex, 1 MP a hexside; a destroyed gyro allows one hexside a turn (p. 46) — `TODO(rules)`: a prone 'Mech that could stand can't choose to turn without standing.
- ✅ Minimum movement (p. 49): running, one hex straight ahead for all MP, even if it costs more.
- ✅ Movement piloting rolls (`MovePsr`): rolled the moment the hex is entered for running into water, rubble, backward level changes and landing in water (a failure ends the move with a fall); rolled after the move for running 1+ hex with a gyro/hip hit or leg gone, and jumping with gyro, leg or leg actuator damage.
- ⬜ Skidding: not in the Core Rulebook; `Skid` is kept for an optional rule but never used.
- ⬜ Lateral shift (optional rule).

## Record sheets
- ✅ Internal structure by tonnage (standard structure).
- ✅ Armor per location, rear armor on torsos, maximum armor check.
- ✅ Critical slot layout: engine, gyro, cockpit, sensors, life support, actuators, equipment.
- 🟡 Design weight check (`DesignWeight`): structure, engine, gyro, cockpit, heat sinks, jump jets, armor, weapons and ammo add up to the tonnage — `TODO(rules)`: engine weight table is general knowledge, not in the Core Rulebook.
- 🟡 Heat sinks: single (1 heat) or double (`"heat_sink_type": "double"`, pp. 89, 103: 2 heat each, 3 slots each, a hit on any slot destroys that sink, 2 extra each under water up to 6); `TODO(rules)`: 10 engine-integral for every design.
- ⬜ Tonnage / construction validation (engine, armor and equipment weights).
- 🟡 Heat scale effects (MP, to-hit, shutdown, ammo explosion) — `TODO(rules)`: verify thresholds.

## Line of sight
- ✅ LOS levels (p. 57): ground (water bottom) + 2 standing / 1 prone. A hex intervenes if its top (hill; woods +2; building roof) is at least both LOS levels, or at least the attacker's and next to it, or at least the target's and next to it. Intervening hills and buildings block; woods add 1/2 points, 3 block.
- ✅ Divided LOS (along a hexside): the target's side chooses; the game takes the side worse for the attacker.
- ✅ Partial cover from terrain (p. 66): a standing target next to a hex one level above its ground, on the line, gets +1 and leg hits strike the cover (a building takes the damage), unless the attacker's LOS level is higher; indirect fire ignores it; civilian buildings and woods give none.
- 🟡 Water combat (`WaterCombat`, pp. 62, 66-67, 127): underwater = depth 2+ or prone in depth 1, wading = standing in depth 1. No shots across the water line; only energy weapons fire from a submerged location (a wading 'Mech's leg weapons only at targets in water, its other weapons not at underwater targets); shots from underwater, or from leg weapons at a wading target, hit legs on the Kick table with no partial cover; underwater shots need a line of water hexes; energy weapons fire one range bracket longer, long range out. Water never blocks line of sight — `TODO(rules)`: torpedoes.
- ✅ Hull breaches (`HullBreach`, p. 127): damage to a location under water rolls 2D6, 2-4 floods it; a bare location (no armor, front or rear for a torso) under water floods at once, now or after moving or falling. A flooded location stops working as if destroyed, without explosions or crits (later crits there do nothing except ammo); a flooded leg counts as destroyed, a flooded side torso floods its arm; it stays flooded out of the water. The record sheet marks it.

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
- 🟡 Indirect LRM fire (`IndirectFire`, pp. 62, 70): a friendly 'Mech with line of sight spots one target per turn; +1 indirect, + spotter's movement, +1 if the spotter also attacks (and +1 to the spotter's own attacks); terrain counted from the spotter; a 'Mech that declared a charge or DFA can't spot.
- ⬜ Called shots, aimed shots.

## Damage
- ✅ Hit location tables (front/rear, left, right) — `TODO(rules)`: verify.
- ✅ Armor → structure → transfer inward; rear armor on torsos.
- ✅ Side torso destroyed takes its arm; head or CT destroyed destroys the 'Mech.
- ✅ Ammo explosion (pp. 95-96): remaining shots × damage, capped at 20, into structure, transferring structure-to-structure; over the cap the surviving last location loses its armor (rear for a torso); MechWarrior takes 1 hit.
- ✅ Explosive components (`ComponentExplosion`, pp. 96, 184): a Gauss rifle explodes on its first critical hit for 2 damage per slot (14), handled like an ammo explosion (20 cap, CASE, pilot hit); later hits don't explode it again; Gauss slugs never explode — `TODO(rules)`: always treated as activated (p. 180).
- ✅ Advanced energy weapons (pp. 184-188): ER small/medium/large lasers, small/medium/large pulse lasers (-2 to hit), ER PPC (no minimum range), and the Gauss rifle, with table stats.
- ✅ Advanced ballistic and missile weapons (`WeaponModes`, pp. 182-192): Ultra ACs fire one or two shots as one attack (2x heat and ammo, cluster column 2, a location per shot); LB 10-X fires slugs or cluster ammo (`ammo:<id>:cluster`, -1 to hit, column 10, 1-point pellets); Streak SRMs hit with every missile, and on a miss don't launch (no heat or ammo); Artemis IV (`<launcher>+artemis`, 1 t, 1 slot) adds +2 to the cluster roll until its slot is hit. Modes are picked in the attack panel — `TODO(rules)`: no Ultra jam in this book (only rotary ACs jam); no ECM; Artemis BV bonus. The computer (`BotModes`) double-fires Ultras when the heat allows and picks LB-X ammo by expected damage.
- ✅ CASE (`"case"` item, p. 96): an explosion in, or transferred into, a CASE location deals at most 10 to its structure and, if it survives, up to 10 more to its armor (rear for a torso); nothing transfers onward. CASE itself takes a slot and 0.5 t. CASE II is not modelled.
- ✅ XL engines (`XlEngine`, `"engine_type": "xl"`, pp. 87, 99): 3 engine slots in each side torso; when a side torso is destroyed its unhit engine slots count as destroyed engine hits, so an Inner Sphere XL 'Mech dies with either side torso. Half the engine weight; BV structure × 0.75 — `TODO(rules)`: XL weight and BV factor are construction data, not in the Core Rulebook; Clan XL (2 slots) not modelled.
- ✅ Endo steel and ferro-fibrous (`"structure_type": "endo_steel"`, `"armor_type": "ferro_fibrous"`, slot items `endo_steel*N`/`ferro_fibrous*N`): half-weight structure, 12% more armor per ton — `TODO(rules)`: weights are construction data.
- ✅ Inapplicable critical slots (p. 94 + errata): empty slots, slots destroyed at any point, and CASE, endo steel and ferro-fibrous slots can't take a critical; the roll picks another slot.
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
- ✅ Consciousness (p. 117): one roll against the current hit total, as soon as a 'Mech's move is over in the Movement Phase, otherwise after the phase's damage, PSRs and falls; wake-up rolls in later End Phases only.

## Physical attacks
- ✅ Modifiers (pp. 76-77, `PhysicalMods`): piloting base plus every ranged modifier except heat and sensors (movement, woods, partial cover, prone -2, immobile -4); piloting roll modifiers don't apply.
- ✅ Punch: piloting − 1, ceil(tons/10), Punch table; arm in front or on its side, arm didn't fire, shoulder working; no hand +1, broken/missing upper or lower arm +2 and half damage (round down) each.
- ✅ Kick: piloting − 1, ceil(tons/5), Kick table (full Hit table vs prone); both hips working, no leg gone, front of the feet, that leg didn't fire; leg actuators in either leg count (foot +1, upper/lower +2 and half damage). Target rolls; a miss makes the kicker roll.
- ✅ One kind per turn: one or two punches, one kick, or a push.
- ✅ Different Levels table (p. 77): standing target 1 up: punch on the Kick table, no kick; 1 down: kick on the Punch table, no punch; prone target: kick at the same level, punch from 1 below, nothing from above (DFA only).
- ✅ Push: piloting − 1, both arms, no arm fired, same level, straight ahead of the feet, +2 per broken shoulder; target not charging. Mutual successful pushes: nobody moves, both roll.
- ✅ Charge (p. 78): walk/run (not jump) ending next to and facing a standing enemy within 1 level, with MP left to enter its hex (may start adjacent; not by minimum movement); piloting + comparative piloting (immobile = 4) + both movement mods + woods, no partial cover; target takes ceil(tons/5 × (attacker TMM + 1)) counting the target hex, attacker ceil(target tons/10), in 5s; both roll at +2; target shoved, attacker follows. A miss moves nobody.
- ✅ Death from above (pp. 79-81): jump; comparative piloting + 3 for the jump, no terrain mods; ceil(tons/10 × 3) on the Punch table (prone target: Rear column of the full table), ceil(tons/5) to own legs; target pushed to the nearest open hexside, both roll at +2. Miss: target steps aside, attacker lands in its hex and falls 2 levels onto its back. No room: target (hit) or attacker (miss) destroyed.
- ✅ A 'Mech can be the target of only one charge, DFA or push per turn; a charging 'Mech can't be charged or pushed.
- ✅ Displacement waits until every physical attack of the phase is rolled (p. 76).
- ✅ Displacement (pp. 113-114): domino effect (roll to step forward/back, else pushed on and falls; crushed with nowhere to go), off the map destroys, 2+ levels down is a fall, 3+ up can't happen.
- ✅ A declared DFA can't be called off (p. 80): a failed piloting roll in the Weapon Attack Phase doesn't drop the attacker, the DFA misses instead; it also misses if the attacker is prone or unconscious, or needs 13+.
- ✅ Physical attacks and water (p. 77): an underwater target can only be reached from underwater, or kicked from depth 1; damage to a submerged location is halved (rounded down); no DFA from depth 2+.
- 🟡 `TODO(rules)`: an attacker felled by an automatic fall is treated like a failed roll.
- ✅ Hatchets and swords (`MeleeWeapons`, pp. 81-82, 194-196): hatchet piloting -1 for ceil(tons/5), sword piloting -2 for ceil(tons/10)+1, full Hit Location Table; arm not fired, target in front or on that arm's side; destroyed hand or shoulder blocks it, missing/broken lower arm or broken upper arm +2 each; a crit on its slots destroys it; one swing replaces all other physical attacks — `TODO(rules)`: the optional Punch/Kick table at +4, swings at other levels or prone targets; slots/weight (tons/15, sword tons/20) are construction knowledge. The computer (`BotPhysical`) swings a hatchet, sword or club when it beats its punches or kick.
- ✅ Clubs (p. 79): pick up a tree in woods or a girder in rubble instead of firing; piloting -1, ceil(tons/5), full table, target in front, no arm weapon fired, both hands and shoulders working, +2 per broken arm actuator; the target makes a piloting roll; a tree breaks after one hit — `TODO(rules)`: limb clubs, dropping a club when an actuator breaks.

## Buildings
- ✅ Classes (p. 131): civilian, light, medium, heavy, hardened with Threshold 8/10/14/16 and Destroy Check 7+/9+/10+/11+; height in levels; every building hex +1 MP (errata).
- ✅ Forced entry (p. 132): only heavy enough 'Mechs (medium buildings: medium+, heavy: heavy+, hardened: assault); piloting roll at +1 per hex; failure doesn't fall but forces a Destroy Check, and a destroyed hex comes down on the 'Mech at once.
- ✅ Civilian buildings: a 'Mech walking or jumping in flattens them (jumps ignore their height); any damage destroys them; rubble only if 4+ levels tall.
- ✅ Destroy Checks (p. 135): each attacker's damage to a hex is added up; at or over the Threshold it rolls 2D6 (+1 at 21-30 damage, +1 per further 10) once its attacks are done; damage is then forgotten. Hexes destroyed in an attack phase come down at its end.
- ✅ Targets inside (p. 136): +2 if the building is at least as tall as the 'Mech (2 standing, 1 prone); walls don't soak damage; misses don't hit the building. A standing 'Mech in a level 1 building has partial cover: +1, and leg hits (and Kick table hits, but not charges) strike the building.
- ✅ Collapse (pp. 136-137): rubble; a 'Mech inside takes half the Threshold per building level above it, 5-point groups from the front. No fall.
- ✅ Shooting buildings (p. 135): -4, from the next hex always hits, cluster weapons hit with every missile.
- ✅ Buildings block line of sight like a hill as tall as the roof.
- ✅ Careful entry (p. 133): running straight into the building hex ahead as the whole move needs no entry roll and works for any building class.
- ✅ Shoved into a building (p. 132): the 'Mech gets in whatever its weight, and the hex takes an immediate Destroy Check.
- 🟡 Roofs (`Roofs`, pp. 132-137): jump on; walk/run roof to roof at 1 MP (same level, or one down going forward), never off to the ground; heavier than the support limit: Destroy Check at +2 per class over; a collapsing roof drops the 'Mech the building's height; roof height counts for line of sight and physical attacks — `TODO(rules)`: a 'Mech inside and one on the roof of the same hex, shoved onto a roof, sight between roofs and insides.
- ✅ Smashing in (p. 133): a player may choose to fail the entry roll on purpose; no roll is made and the building takes the usual destroy check ("Smash in" button).
- 🟡 `TODO(rules)`: DFA into a level 1 building, Castles Brian.
- 🟡 Fire (`Fire`, pp. 123-124, 136): burning hexes from the map; flamer hits on a 'Mech-scale building light it once a phase's heat reaches its class's fire heat x height (end of phase); it burns until the building collapses. Moving through a burning hex +2 heat (not jumping), in one at the Heat Phase +5. Fire makes light smoke two levels above the ground or roof: +1 to hit a 'Mech in it and 1 line-of-sight point, never past 2 per hex with woods; none for a 'Mech inside the burning building — `TODO(rules)`: lighting woods, other smoke.
- ⬜ Physical attacks on buildings, bridges as structures, basements.

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
- 🟡 Battle Value (`BattleValue`, `BvText` explains it) — `TODO(rules)`: simplified BV 2 (rear weapons half, 15 per ton of ammo, no CASE).
- ✅ Pilot skill adjusts Battle Value (`BvSkill`, multipliers in `data/bv_skill.json`); the force builder cycles Green / Regular / Veteran / Elite per side.
- ✅ Hot-seat play, or either side played by the computer (`Bot`): it scores every reachable
  end hex by expected damage dealt vs taken plus heat, picks the best target and holds weapons
  to stay cool, punches/kicks when worth the fall risk, and logs why (when explanations are on).
- ⬜ Bot charges, DFAs and pushes; smarter focus fire and retreat.
- ✅ Terrain: clear, rough, rubble, light/heavy woods, pavement, water depth 1-2, hills.
- ✅ Maps: Test Valley, River Crossing, Rolling Hills, Dense Forest, City Outskirts.
- ✅ Tapping an empty hex explains its movement cost, cover and cooling.
- ⬜ Bridges as structures, fire and smoke.
