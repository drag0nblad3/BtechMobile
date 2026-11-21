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
- ✅ Heat scale effects (MP, to-hit, shutdown, ammo explosion): thresholds checked against the book's heat data table.

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
- ✅ Cluster hits table, all 13 columns (p. 74), checked against the book; LRMs in 5-point groups, SRMs per missile.
- ✅ Ammo used per shot; no ammo, no shot.
- ✅ Flamers (p. 183): a hit deals damage and the same amount of heat to the target; outside heat is capped at 15 per turn.
- 🟡 Indirect LRM fire (`IndirectFire`, pp. 62, 70): a friendly 'Mech with line of sight spots one target per turn; +1 indirect, + spotter's movement, +1 if the spotter also attacks (and +1 to the spotter's own attacks); terrain counted from the spotter; a 'Mech that declared a charge or DFA can't spot.
- ✅ Aimed shots (`AimedShot`, p. 70): against an immobile target, a non-cluster, non-indirect shot (no Ultra double fire, no LB-X cluster rounds) may aim at a location; -4 kept, but a head shot drops it and takes +3; on a hit 1D6 4+ lands there, else the location is rolled; with partial cover legs can't be chosen, the cover modifier is dropped and leg rolls are rerolled. The weapon panel shows an "Aim at" button for immobile targets (`AimPicker`); the computer aims too (`BotAim`).

## Damage
- ✅ Hit location tables (front/rear, left, right), punch and kick tables (pp. 74, 81): checked against the book; the front punch table had arms and side torsos swapped, now fixed.
- ✅ Armor → structure → transfer inward; rear armor on torsos.
- ✅ Side torso destroyed takes its arm; head or CT destroyed destroys the 'Mech.
- ✅ Ammo explosion (pp. 95-96): remaining shots × damage, capped at 20, into structure, transferring structure-to-structure; over the cap the surviving last location loses its armor (rear for a torso); MechWarrior takes 1 hit.
- ✅ Explosive components (`ComponentExplosion`, pp. 96, 184): a Gauss rifle explodes on its first critical hit for 2 damage per slot (14), handled like an ammo explosion (20 cap, CASE, pilot hit); later hits don't explode it again; Gauss slugs never explode — `TODO(rules)`: always treated as activated (p. 180).
- ✅ Advanced energy weapons (pp. 184-188): ER small/medium/large lasers, small/medium/large pulse lasers (-2 to hit), ER PPC (no minimum range), and the Gauss rifle, with table stats.
- ✅ Advanced ballistic and missile weapons (`WeaponModes`, pp. 182-192): Ultra ACs fire one or two shots as one attack (2x heat and ammo, cluster column 2, a location per shot); LB 10-X fires slugs or cluster ammo (`ammo:<id>:cluster`, -1 to hit, column 10, 1-point pellets); Streak SRMs hit with every missile, and on a miss don't launch (no heat or ammo); Artemis IV (`<launcher>+artemis`, 1 t, 1 slot) adds +2 to the cluster roll until its slot is hit. Modes are picked in the attack panel — `TODO(rules)`: no Ultra jam in this book (only rotary ACs jam); Artemis BV bonus. Enemy ECM cancels Artemis (`Ecm`). The computer (`BotModes`) double-fires Ultras when the heat allows and picks LB-X ammo by expected damage.
- ✅ Rotary autocannons (`RotaryAc`, `rotary_ac2`/`rotary_ac5`, p. 183): 1-6 shots as one attack (heat and ammo per shot, cluster column = shots); more than one shot jams it on an attack roll of 2 (2-3 shots), 3- (4-5) or 4- (6), hit or not; a jammed RAC can't fire until a Gunnery +3 roll at the end of the weapon phase clears it, only if the 'Mech stood still or walked. The computer fires four shots and tries to clear jams — `TODO(rules)`: clearing is picked in the weapon phase, not declared in the Movement Phase.
- ✅ Narc missile beacons (`Narc`, `narc_beacon`, `ammo:<launcher>:narc`, p. 188): a beacon hit attaches a pod where it lands (aimed or rolled, no damage), lost with that location; from the next turn the pod's side gets -1 to hit and +2 on the cluster roll with Narc-equipped missiles against that 'Mech, unless it stands in ECM hostile to that side; Narc-equipped missiles don't use Artemis; Narc ammo explodes for 2 a pod; the record sheet lists pods. The computer picks Narc ammo when it homes, and tags its volley's target with a beacon when its side has Narc-equipped missiles (`BotNarc`) — `TODO(rules)`: indirect fire at a pod without a spotter, iNarc and special pods, AMS against pods, partial cover on beacon hits.
- ✅ Targeting computers (`TargetingComputer`, `targeting_computer` item, p. 200): -1 to hit for direct-fire energy and ballistic weapons (not flamers, machine guns, missiles, LB-X cluster rounds or Ultra double fire); allows aimed shots at moving 'Mechs (+3 instead of the -1, no head, no pulse lasers); aimed pulse shots never get the -1; a critical hit destroys it — `TODO(rules)`: size (1 slot and 1 t per 4 t of linked weapons) is construction data; no BV bonus.
- ✅ Anti-missile systems (`AntiMissile`, `ams` + `ammo:ams`, p. 206): when a missile weapon hits from a direction the AMS's location covers, it engages: -4 to the cluster roll (below 2 shoots down every missile), a Streak counts as a 7; 1 ammo and 1 heat each, two attacks a turn per AMS, one AMS per attack, not while the MechWarrior is out; AMS ammo explodes for 2 per shot; AMS BV counts as defensive — `TODO(rules)`: the defender always engages; laser AMS and single-missile weapons not modelled.
- ✅ Clan weapons (`tech: "clan"`, `c_*` ids, book pp. 251-252 tables): ER, pulse, ER pulse (-1), heavy (+1) and micro lasers, ER PPC, flamers, light/standard/heavy machine guns, Ultra and LB-X ACs 2-20, Gauss, SRM, Streak SRM, LRM (no minimum range) and AMS, with their own heat, damage, ranges, weight and slots — ⬜ ATM, HAG, Streak LRM, chemical lasers, plasma cannon, ProtoMech ACs. `TODO(rules)`: weapon BVs are general BV 2 knowledge, not in the Core Rulebook.
- ✅ Guardian ECM suites (`Ecm`, `guardian_ecm` item, 1.5 t, 2 slots, p. 200): an enemy's working suite jams 6 hexes around it; an Artemis IV launcher whose attacker or target is inside it loses the +2 cluster bonus; Artemis never helps indirect fire (p. 188); a critical hit or shutdown stops the suite; it adds 61 to defensive BV — `TODO(rules)`: always on; water-line blocking, Angel ECM, Narc, C3 and probes not modelled.
- ✅ CASE (`"case"` item, p. 96): an explosion in, or transferred into, a CASE location deals at most 10 to its structure and, if it survives, up to 10 more to its armor (rear for a torso); nothing transfers onward. CASE itself takes a slot and 0.5 t. CASE II is not modelled.
- ✅ XL engines (`XlEngine`, `"engine_type": "xl"`, pp. 87, 99): 3 engine slots in each side torso; when a side torso is destroyed its unhit engine slots count as destroyed engine hits, so an Inner Sphere XL 'Mech dies with either side torso. Half the engine weight; BV structure × 0.75 — `TODO(rules)`: XL weight and BV factor are construction data, not in the Core Rulebook.
- ✅ OmniMechs (`OmniConfig`, p. 20): a construction feature with no special battle rules here; each configuration (Prime, A, B, ...) is its own design built from one chassis file, and the record sheet names it — ⬜ battle armor riding OmniMechs (no battle armor), swapping pods between battles (campaign).
- ✅ Clan roster: Kit Fox, Adder, Nova, Stormcrow, Mad Dog, Hellbringer, Summoner, Timber Wolf and Dire Wolf OmniMechs (16 configurations, Clan parts only) — `TODO(rules)`: loadouts adapted to whole-ton ammo; check against the readouts.
- ✅ Clan construction (`ClanTech`, `"tech_base": "clan"`): a Clan XL has 2 engine slots a side, so losing one side torso is 2 engine hits and the 'Mech fights on (the bot only counts a side torso as a kill shot once the engine is already hit); double heat sinks 2 slots; CASE built into every location; ferro-fibrous 20% more points a ton; targeting computer 1 t per 5 t; BV structure × 0.875 for a Clan XL — `TODO(rules)`: construction data, not in the Core Rulebook.
- ✅ Endo steel and ferro-fibrous (`"structure_type": "endo_steel"`, `"armor_type": "ferro_fibrous"`, slot items `endo_steel*N`/`ferro_fibrous*N`): half-weight structure, 12% more armor per ton — `TODO(rules)`: weights are construction data.
- ✅ Inapplicable critical slots (p. 94 + errata): empty slots, slots destroyed at any point, and CASE, endo steel and ferro-fibrous slots can't take a critical; the roll picks another slot.
- ✅ Head hits (p. 117): every hit that damages the head is 1 MechWarrior hit, even if the armor holds.
- ✅ 20-damage piloting roll counts the armor and structure pips actually marked off, including falls and explosions.

## Heat
- ✅ Heat from walking (1), running (2), weapons fired, engine hits (5 each).
- ✅ Dissipation 1 per working heat sink.
- ✅ Shutdown (`HeatShutdown`, pp. 104-105): roll at 14+ (4+, 6+, 8+, 10+, auto at 30 or with an unconscious warrior), resolved before ammo; a shut-down 'Mech doesn't fall but can't act, fails piloting rolls and gets no engine-hit heat.
- ✅ Voluntary shutdown (`VoluntaryShutdown`, p. 105, errata p. 104): the record sheet's button asks to shut down at the next Heat Phase, or to restart a 'Mech shut down by choice in a later one (automatic below 14 heat, else a conscious MechWarrior rolls the avoid number, never at 30+); it stays down until restarted — `TODO(rules)`: the request can be made any time before the Heat Phase; the computer never shuts down on purpose.
- ✅ Restart: automatic below 14 (even unconscious); otherwise a conscious warrior rolls the same number; never at 30+.
- ✅ Ammo explosion roll at 19+ (4+, 6+, 8+); the bin with the most damage per shot cooks off, ties to the most shots left.
- ✅ Water cooling (p. 103): submerged heat sinks cool double, max +6; standing in depth 1 only leg sinks are under.
- ✅ Outside heat (flamers) capped at 15 per turn.
- ✅ Life support hit: 1 MechWarrior hit per Heat Phase at heat 10-19, 2 at 20+; 1 in the End Phase when fully under water.
- ✅ Jumping heat (1 per hex, min 3).

## Battlefield conditions
- ✅ Conditions for the whole map (`Conditions`, pp. 120-121) from a scenario's `"conditions"` block or the start screen's Conditions button; the log names them on turn 1 and explains each at Full.
- ✅ Extreme cold / heat 1-3 (`ExtremeTemp`, p. 120): +2 heat shed (cold) or gained (heat) per level each Heat Phase; shutdown, restart and ammo avoid numbers -1/+1 per level (2 or less passes, past 12 fails); life support: in the cold, one MechWarrior hit per level instead of heat hits, minus 1/2/3 at 5-10/11-20/21+ heat; in the heat, +1 hit per level whenever heat deals life support hits — `TODO(rules)`: water freezing to ice / drying to sinkholes; torso-mounted cockpits (not in the game).
- ✅ Gravity (`Gravity`, p. 121): rounded to 0.1 G; fall and building collapse damage times G, rounded up; every jump owes a piloting roll at -1 away from 1 G.
- ✅ Night (p. 121): no effect on 'Mechs (explained in the log).
- ✅ Wind (`Wind`, p. 121): +1 to every piloting roll outside buildings (a roof is outside); a jump (not a DFA) owes a +1 landing roll whose failure is a 1-level fall, and the other jump rolls skip the general +1; a successful DFA's attacker roll gets +1 and an attacker falling from a DFA falls 1 level more; smoke and fog are blown away.
- ✅ Low visibility (`LowVisibility`, p. 121): +1 to every ranged attack (including shots at buildings and woods); at the start of the Weapon Attack Phase each active 'Mech makes a sensor check (p. 113: piloting, +2 for one sensor hit, impossible with two, never a fall) and passing removes the +1 for that turn — `TODO(rules)`: active probes (none in the game yet).
- ✅ Rain and snowfall (p. 121): rain lays mud on every hex but depth 1+ water, pavement and buildings and stops all fires; snowfall lays snow on every hex but depth 1+ water.
- ✅ Ice, mud and snow (`Surfaces`, pp. 124-125, errata p. 124): map `"surface"` hexes or laid down by conditions (Extreme Cold freezes water, Extreme Heat dries it into sinkholes). Ice: frozen water is walked on at its surface, +1 to any piloting roll made there, no roll to enter. Mud: a running 'Mech turning in mud rolls at -1 at once and falls there on a failure. Snow: ending a move in snow sheds +1 heat per leg (+4 prone; none inside a building). None of them can burn. Shown on the map as pale blue, brown and white hex tops.
- 🟡 Avalanches (`Avalanche`, p. 125, errata p. 125): a fall in snow next to a lower hex slides down (snow first, else random), rolling on while the slide continues in snow; one fall at the end for the starting levels + height dropped + 1 per heavy woods — `TODO(rules)`: sliding into another 'Mech (stops short instead of a domino effect); slide rolls use only the 'Mech's damage modifiers.
- ✅ Smoke and fog hexes (`Obscurant`, p. 124): map `"fog"` hexes, light or heavy, act as light/heavy woods two levels high for line of sight and to-hit; burning hexes are light smoke; with woods and each other a hex never passes +2 or 2 line-of-sight points.

## Missions
- ✅ Missions (`Mission`, `MissionFlow`, pp. 225-233) from a scenario's `"mission"` block; without one the last side standing wins. The log gives the briefing on turn 1 and the HUD shows the Victory Point score.
- ✅ Objectives and control (`Objective`, `ObjectiveControl`, p. 232): control radius; the side with more non-crippled, standing, mobile 'Mechs inside it holds it; ties hold nothing. End Phase scoring per mission: each objective's VP, pairs of friendly + enemy objectives, or 2-of-3 / all-3 thresholds.
- ✅ Victory Points (`VictoryPoints`, p. 227): Unit VP = BV / 100 rounded up (min 1, skill-adjusted BV) for destroyed (or crippled) enemies; most VP wins; ties go to Unit VP when objectives scored, then to the side that spent less BV. VP missions end after their last turn, or early once one side has nothing left and the other already leads.
- ✅ Random Duration (`RandomDuration`, p. 233): from turn 7, 1 / 1-2 (turns 8-9) / 1-4 (turn 10+) on a d6 ends the mission after that turn.
- ✅ Crippled (`Crippled`, p. 228; only with Forced Withdrawal): two engine hits, two destroyed limbs including a leg, or a destroyed side torso (standard engine: a piloting roll ignores the first torso, which still counts as a limb).
- 🟡 Forced Withdrawal (`ForcedWithdrawal`, p. 230): a crippled 'Mech must end each move closer to its home edge when it can, may leave by it (its side earns half its Unit VP), can't hold objectives, and surrenders after two turns in a row without getting closer; the computer retreats with `BotWithdraw` — `TODO(rules)`: "spend at least half its MP getting closer" is only enforced through the end hex.
- ✅ Leaving the battlefield (p. 225): where the mission or withdrawal allows, a move ending on that edge with 1 MP to spare can go off the map (the Leave map button).

## Critical hits
- ✅ Crit check when structure is damaged or on a hit-location roll of 2: 8-9 one, 10-11 two,
  12 three (head/limb blown off), checked against the book (p. 91).
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
- 🟡 Fire (`Fire`, pp. 123-124, 136): burning hexes from the map; flamer hits on a 'Mech-scale building light it once a phase's heat reaches its class's fire heat x height (end of phase); it burns until the building collapses. Moving through a burning hex +2 heat (not jumping), in one at the Heat Phase +5. Fire makes light smoke two levels above the ground or roof: +1 to hit a 'Mech in it and 1 line-of-sight point, never past 2 per hex with woods; none for a 'Mech inside the burning building — `TODO(rules)`: other smoke.
- ✅ Setting woods alight (`WoodsFire`, p. 123): a flamer may shoot a woods hex directly (-4, line of sight and range as usual, no automatic hit next door); hits totalling 4 heat in one phase, from any attackers, light it at the end of the phase and it burns for the rest of the battle. Tap the woods in the weapon phase — `TODO(rules)`: jungle, foliage, ice/mud/snow/swamp and rain exceptions (not on our maps).
- ✅ Physical attacks on buildings (`BuildingMelee`, p. 135): tap an adjacent building in the Physical Attack Phase to punch (two arms), kick or swing a hatchet, sword or club at it; they always hit, no piloting roll for a kick, and the damage counts toward the attacker's Destroy Check — `TODO(rules)`: kicks need the building to fill the attacker's leg level, punches and swings the level above (our reading).
- ⬜ Bridges as structures, basements.

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
- ✅ The catalog filters All / Inner Sphere / Clan and shows each OmniMech chassis once with a button cycling its configurations (`DesignFilter`, `ForceCatalog`); with full explanations it says what Clan tech and OmniMechs mean. Mixed Clan and Inner Sphere forces are allowed — ⬜ Clan Stars of 5, Clan honor rules (zellbrigen).
- 🟡 Battle Value (`BattleValue`, `BvText` explains it) — `TODO(rules)`: simplified BV 2 (rear weapons half, 15 per ton of ammo, no CASE).
- ✅ Pilot skill adjusts Battle Value (`BvSkill`, multipliers in `data/bv_skill.json`); the force builder cycles Green / Regular / Veteran / Elite per side.
- ✅ Hot-seat play, or either side played by the computer (`Bot`): it scores every reachable
  end hex by expected damage dealt vs taken plus heat, picks the best target and holds weapons
  to stay cool, punches/kicks when worth the fall risk, and logs why (when explanations are on).
- 🟡 Bot charges and death from above (`BotCharge`): tried at each end position with an enemy straight ahead, valued as expected damage + a bonus for the target's piloting roll − part of its own damage − the fall from a missed DFA, used only when it beats shooting. Pushes (`BotPhysical`) are valued by the chance to knock the target down, a ledge fall, or shoving it off the map; it picks up a club when its guns would do little and an enemy is within 3 hexes. Aimed shots (`BotAim`): at a sitting target, or with a targeting computer, it aims a shot when the chance of hitting times the value of that location (half the hits land there; finishing the head, CT or an XL side torso is worth most) beats an ordinary shot. ⬜ Attacking buildings; smarter focus fire and retreat.
- ✅ Terrain: clear, rough, rubble, light/heavy woods, pavement, water depth 1-2, hills.
- ✅ Maps: Test Valley, River Crossing, Rolling Hills, Dense Forest, City Outskirts.
- ✅ Tapping an empty hex explains its movement cost, cover and cooling.
- ⬜ Bridges as structures, fire and smoke.
