class_name ToHitCalc
extends RefCounted
## Builds the to-hit number for one weapon shot (Total Warfare, Combat).
## Every modifier carries a short reason, which the explanation layer shows.


static func weapon(state: GameState, attacker: Unit, w: MountedWeapon, target: Unit,
		secondary: bool = false) -> ToHit:
	var th := ToHit.new()
	if target == null or target.destroyed:
		th.impossible = "No target"
		return th
	if not attacker.can_fire(w):
		th.impossible = "%s can't fire (%s)" % [w.def.name,
				"no ammo" if not w.destroyed and not attacker.is_location_destroyed(w.loc) else "destroyed"]
		return th
	var arc_id := FiringArc.arc(attacker.coord, attacker.facing, target.coord)
	if not FiringArc.weapon_covers(w.loc, w.rear, arc_id):
		th.impossible = "Target is in your %s arc; %s can't point there" % [
				FiringArc.NAMES[arc_id], w.label()]
		return th
	var los := LineOfSight.check(state.map, attacker, target)
	if los["blocked"]:
		th.impossible = "No line of sight (%s)" % los["reason"]
		return th
	var dist := Hex.distance(attacker.coord, target.coord)
	var br := w.def.bracket(dist)
	if br == WeaponDef.Bracket.OUT:
		th.impossible = "Out of range (%d hexes, max %d)" % [dist, w.def.long_range]
		return th
	th.add("Gunnery", attacker.pilot.gunnery, "Your MechWarrior's gunnery skill is the base number.")
	add_movement(th, attacker, target)
	match br:
		WeaponDef.Bracket.MEDIUM:
			th.add("medium range", 2, "%d hexes is medium range for %s (%s)." % [dist, w.def.name, w.def.range_text()])
		WeaponDef.Bracket.LONG:
			th.add("long range", 4, "%d hexes is long range for %s (%s). Closing in would remove this." % [dist, w.def.name, w.def.range_text()])
	if w.def.min_range > 0 and dist <= w.def.min_range:
		th.add("minimum range", w.def.min_range - dist + 1,
				"%s is clumsy up close: inside its minimum range of %d, each hex nearer is +1." % [w.def.name, w.def.min_range])
	add_conditions(th, state, attacker, target, los)
	if Location.is_arm(w.loc):
		add_arm_actuators(th, attacker, w.loc)
	if secondary:
		var fwd := arc_id == FiringArc.FRONT
		th.add("secondary target", 1 if fwd else 2,
				"Shooting at a second target costs +1 in front of you, +2 to the side or rear.")
	return th


## Attacker and target movement.
static func add_movement(th: ToHit, attacker: Unit, target: Unit) -> void:
	match attacker.move_mode:
		MoveMode.Kind.WALK:
			th.add("you walked", 1, "Walking makes your own aim worse by 1.")
		MoveMode.Kind.RUN:
			th.add("you ran", 2, "Running makes your own aim worse by 2. Walking would make it +1.")
	var tm := target_movement_mod(target.hexes_moved)
	if tm > 0:
		th.add("target moved %d hexes" % target.hexes_moved, tm,
				"Fast targets are harder to hit: 3-4 hexes +1, 5-6 +2, 7-9 +3, 10+ +4.")


static func add_conditions(th: ToHit, state: GameState, attacker: Unit, target: Unit,
		los: Dictionary) -> void:
	var hp := HeatScale.to_hit_penalty(attacker.heat)
	if hp > 0:
		th.add("heat %d" % attacker.heat, hp, "Running hot shakes your targeting: +1 at 8 heat, rising.")
	if attacker.sensor_hits > 0:
		th.add("sensor damage", 2 * attacker.sensor_hits, "Damaged sensors make every shot harder.")
	if attacker.prone:
		th.add("you are prone", 2, "Firing from the ground is +2.")
	if los["woods"] > 0:
		th.add("woods in the way", los["woods"],
				"Light woods between you add +1 each, heavy woods +2. Three points block the shot.")
	var tile := state.map.get_tile(target.coord)
	var tw := LineOfSight.woods_value(tile) if tile else 0
	if tw > 0:
		th.add("target in woods", tw, "The target is hiding in %s." % tile.terrain.name.to_lower())
	if in_partial_cover(state.map, target):
		th.add("partial cover", 1, "The target's legs are under water; leg hits are absorbed.")
	if target.prone:
		var adjacent := Hex.distance(attacker.coord, target.coord) <= 1
		th.add("target prone", -2 if adjacent else 1,
				"A 'Mech on the ground is easier to hit from next to it (-2), harder from afar (+1).")
	if target.shutdown or not target.pilot.conscious:
		th.add("target immobile", -4, "A shut-down or unconscious 'Mech can't dodge: -4.")


static func add_arm_actuators(th: ToHit, u: Unit, loc: int) -> void:
	if u.def.has_actuator(loc, "shoulder") and not u.has_working_actuator(loc, "shoulder"):
		th.add("shoulder hit", 4, "A damaged shoulder makes aiming that arm much harder.")
		return
	for a in ["upper_arm", "lower_arm"]:
		if u.def.has_actuator(loc, a) and not u.has_working_actuator(loc, a):
			th.add(a.replace("_", " ") + " hit", 1, "A damaged arm actuator throws off the aim.")


## Target movement modifier from hexes moved this turn.
static func target_movement_mod(hexes: int) -> int:
	if hexes >= 25:
		return 6
	if hexes >= 18:
		return 5
	if hexes >= 10:
		return 4
	if hexes >= 7:
		return 3
	if hexes >= 5:
		return 2
	if hexes >= 3:
		return 1
	return 0


## Standing in depth 1 water.
static func in_partial_cover(map: BattleMap, u: Unit) -> bool:
	var tile := map.get_tile(u.coord)
	return tile != null and tile.is_water() and tile.depth == 1 and not u.prone
