class_name ToHitCalc
extends RefCounted
## Builds the to-hit number for one weapon shot (Total Warfare, Combat).
## Every modifier carries a short reason, which the explanation layer shows.


## `point_blank`: a hidden unit's ambush shot (PointBlank), no target movement modifier.
static func weapon(state: GameState, attacker: Unit, w: MountedWeapon, target: Unit,
		secondary: bool = false, point_blank := false) -> ToHit:
	var th := ToHit.new()
	if target == null or target.destroyed:
		th.impossible = "No target"
		return th
	if attacker.asset != null:
		return AssetFire.to_hit(state, attacker, w, target)
	th.impossible = BaFire.problem(state, attacker)
	if th.impossible != "":
		return th
	var swarm := BaSwarm.fire_check(attacker, w, target)
	if swarm != null:
		return swarm
	if BaSwarm.is_swarm(w):
		return BaSwarm.to_hit(state, attacker, target)
	if BaLegAttack.is_leg_attack(w):
		return BaLegAttack.to_hit(state, attacker, target)
	if target.carrier_id() >= 0:
		th.impossible = "It is riding inside a transport"
		return th
	if target.coord == attacker.coord:
		th.impossible = "A 'Mech can't shoot at a unit in its own hex"
		return th
	if secondary and Stealth.active(target):
		th.impossible = "Stealth armor: it can only be your primary target"
		return th
	if w.def.ams:
		th.impossible = "Anti-missile system: it shoots down incoming missiles on its own"
		return th
	if ApolloSaturation.on(w):
		return ApolloSaturation.to_hit(state, attacker, w, target.coord)
	if w.mode == PpcCapacitor.CHARGE:
		th.impossible = "%s is charging its capacitor instead of firing" % w.def.name
		return th
	if not attacker.can_fire(w):
		th.impossible = "%s can't fire (%s)" % [w.def.name, "jammed" if w.jammed else
				("no ammo" if not w.destroyed and not attacker.is_location_destroyed(w.loc) else "destroyed")]
		return th
	if attacker.carry_arm >= 0 and w.loc == attacker.carry_arm:
		th.impossible = "%s is in the arm carrying the objective" % w.def.name
		return th
	var prone_why := ProneFire.blocked(attacker, w)
	if prone_why != "":
		th.impossible = prone_why
		return th
	if ArrowIv.is_arrow(w):
		return ArrowIv.to_hit(state, attacker, w, target)
	if attacker.vehicle != null:
		th.impossible = VehicleFire.arc_problem(attacker, w, target)
		if th.impossible != "":
			return th
		VehicleFire.add_mods(th, attacker, w)
	var arc_id := FiringArc.fire_arc(attacker.coord, FiringArc.weapon_facing(attacker, w.loc), target.coord)
	if attacker.vehicle == null and attacker.ba == null and not FiringArc.weapon_covers(w.loc, ArmFlip.rear(attacker, w), arc_id, attacker.def.quad):
		th.impossible = "Target is in your %s arc; %s can't point there" % [
				FiringArc.NAMES[arc_id], w.label()]
		return th
	var wc := WaterCombat.shot(state.map, attacker, w, target)
	if wc["impossible"] != "":
		th.impossible = wc["impossible"]
		return th
	th.legs_only = wc["legs_only"]
	var los := LineOfSight.check(state.map, attacker, target)
	var spotter: Unit = null
	var pod := false
	if los["blocked"]:
		pod = Narc.indirect(state, attacker, w, target)
		spotter = IndirectFire.spotter(state, attacker, target) if Atm.profile(w).indirect and not pod else null
		if pod:
			los = LineOfSight.none()  # no spotter: only the target's own hex counts (p. 188)
		elif spotter == null:
			th.impossible = "No line of sight (%s)%s" % [los["reason"],
					"; no friendly 'Mech can spot for indirect fire" if Atm.profile(w).indirect else ""]
			return th
		else:
			los = LineOfSight.check(state.map, spotter, target)
		los["cover"] = Hex.INVALID  # indirect fire ignores cover from hills (p. 66)
	else:
		th.impossible = LegFire.blocked(state, attacker, w, target)
		if th.impossible != "":
			return th
	var dist := Hex.distance(attacker.coord, target.coord)
	var p := Atm.profile(w)  # ATM munitions change the ranges
	var br := p.bracket(dist)
	if br == WeaponDef.Bracket.OUT:
		th.impossible = "Out of range (%d hexes, max %d)" % [dist, p.long_range]
		return th
	var c3 := C3.improve(state, attacker, target, p, br) if spotter == null and not wc["under_range"] else {}
	if not c3.is_empty():
		br = c3["br"]
	var wet := " under water" if wc["under_range"] else ""
	if wc["under_range"]:
		if br == WeaponDef.Bracket.LONG:
			th.impossible = "Out of range under water (%d hexes; long range can't be used)" % dist
			return th
		br += 1
	th.add("Gunnery", attacker.pilot.gunnery, "Your MechWarrior's gunnery skill is the base number.")
	add_movement(th, attacker, target, point_blank)
	th.indirect = spotter != null or pod
	if pod:
		Narc.add_indirect(th)
	elif spotter:
		IndirectFire.add_mods(th, state, spotter, target)
		th.spotter_id = spotter.id
	IndirectFire.add_spotting_mod(th, state, attacker)
	var rdist: int = c3.get("dist", dist)
	if not c3.is_empty():
		C3.add_mods(th, c3)
	match br:
		WeaponDef.Bracket.MEDIUM:
			th.add("medium range" + wet, 2, "%d hexes is medium range for %s (%s)%s." % [rdist, p.name, p.range_text(),
					"; water slows the beam by one range bracket" if wet != "" else ""])
		WeaponDef.Bracket.LONG:
			th.add("long range" + wet, 4, "%d hexes is long range for %s (%s)%s. Closing in would remove this." % [rdist, p.name, p.range_text(),
					"; water slows the beam by one range bracket" if wet != "" else ""])
	Stealth.add_mods(th, target, br)
	if p.min_range > 0 and dist <= p.min_range:
		th.add("minimum range", p.min_range - dist + 1,
				"%s is clumsy up close: inside its minimum range of %d, each hex nearer is +1." % [p.name, p.min_range])
	var own := w.def.to_hit_at(br)
	if own != 0:
		th.add(w.def.name, own, "%s is %s accurate than a standard weapon: %+d to hit%s." % [
				w.def.name, "more" if own < 0 else "less", own, " at this range" if not w.def.to_hit_by_range.is_empty() else ""])
	TargetingComputer.add(th, attacker, w)
	Narc.add(th, state, attacker, w, target)
	NarcPods.add_haywire(th, state, attacker)
	if WeaponModes.to_hit_mod(w) != 0:
		th.add("cluster ammo", WeaponModes.to_hit_mod(w), "LB-X cluster rounds spread like a shotgun: -1 to hit, but each pellet only does 1 damage.")
	LowVisibility.add(th, state, attacker, target)
	add_conditions(th, state, attacker, target, ActiveProbe.strip_smoke(los, state, attacker, target))
	if Location.is_arm_of(attacker.def, w.loc):
		add_arm_actuators(th, attacker, w.loc)
	if secondary:
		th.add("secondary target", 1, "Every target after your primary one costs +1.")
	return th


## Attacker and target movement.
static func add_movement(th: ToHit, attacker: Unit, target: Unit, ignore_target := false) -> void:
	add_attacker_movement(th, attacker)
	if target.asset != null:
		return  # fixed TMM, weighed against terrain in add_conditions (AssetFire)
	var jumped := target.move_mode == MoveMode.Kind.JUMP
	var tm := target_movement_mod(target.hexes_moved, jumped)
	if target.landed and not ignore_target:
		th.add("just dropped", CombatDrop.LANDED_MOD, "It fell from the sky this turn: +3, as if it moved very fast.")
		return
	if tm > 0 and (ignore_target or target.tmm_zero):
		th.add("target caught off guard", 0, "A point-blank ambush shot ignores how far the target moved." if ignore_target
				else "It was just found hiding, so its movement doesn't count this turn.")
	elif tm > 0:
		th.add("target %s %d hexes" % [MoveMode.verb_for(target, target.move_mode), target.hexes_moved], tm,
				"Fast targets are harder to hit: 3-4 hexes +1, 5-6 +2, 7-9 +3, 10+ +4; +1 more if it jumped.")


static func add_attacker_movement(th: ToHit, attacker: Unit) -> void:
	match attacker.move_mode:
		MoveMode.Kind.WALK:
			th.add("you walked", 1, "Walking makes your own aim worse by 1.")
		MoveMode.Kind.RUN:
			th.add("you ran", 2, "Running makes your own aim worse by 2. Walking would make it +1.")
		MoveMode.Kind.JUMP:
			th.add("you jumped", 3, "Shooting after a jump is hard: +3.")


static func add_conditions(th: ToHit, state: GameState, attacker: Unit, target: Unit,
		los: Dictionary) -> void:
	add_attacker_conditions(th, attacker, los)
	if target.asset != null:
		AssetFire.add_target_mods(th, state, target)
		return
	var tile := state.map.get_tile(target.coord)
	var tw := LineOfSight.woods_value(tile) if tile else 0
	if tw > 0:
		th.add("target in woods", tw, "The target is hiding in %s." % tile.terrain.name.to_lower())
	var obs := Obscurant.to_hit_mod(state.map, target, tw)
	if obs > 0 and not ActiveProbe.clears(state, attacker, target):
		var what := Obscurant.name_of(tile)
		th.add("target in " + what, obs, "The %s in its hex hides the target like woods (never more than +2 with woods)." % what)
	if th.legs_only:
		th.add("legs only", 0, "Under water only the target's legs can be hit; roll on the Kick table, no partial cover.")
	elif in_partial_cover(state.map, target):
		th.add("partial cover", 1, "The target's legs are under water; leg hits are absorbed.")
	elif BuildingRules.half_inside(state.map, target):
		th.add("partial cover", 1, "The target stands half inside a one-level building; leg hits strike the walls.")
	elif los.get("cover", Hex.INVALID) != Hex.INVALID:
		th.cover_hex = los["cover"]
		th.add("partial cover", 1, "The hex in front of the target (%s) hides its legs; leg hits strike the cover." % Hex.label(th.cover_hex))
	var inside := BuildingRules.inside_mod(state.map, target)
	if inside > 0:
		th.add("inside a building", inside, "The target is fighting from inside a building: +2.")
	if target.prone:
		var adjacent := Hex.distance(attacker.coord, target.coord) <= 1
		th.add("target prone", -2 if adjacent else 1,
				"A 'Mech on the ground is easier to hit from next to it (-2), harder from afar (+1).")
	BaFire.add_target_mod(th, target)
	if is_immobile(target):
		th.add("target immobile", -4, "A shut-down, unconscious or legless 'Mech can't dodge: -4.")


## Heat, sensors, lying down and woods in the way: true for any target.
static func add_attacker_conditions(th: ToHit, attacker: Unit, los: Dictionary) -> void:
	var hp := HeatScale.to_hit_penalty(attacker.heat)
	if hp > 0:
		th.add("heat %d" % attacker.heat, hp, "Running hot shakes your targeting: +1 at 8 heat, rising.")
	if attacker.sensor_hits > 0:
		th.add("sensor damage", 2 * attacker.sensor_hits, "Damaged sensors make every shot harder.")
	if attacker.prone and not Quad.fires_standing(attacker):
		th.add("you are prone", 2, "Firing from the ground is +2, propped up on one arm.")
	if los["woods"] > 0:
		th.add("woods in the way", los["woods"],
				"Light woods between you add +1 each, heavy woods +2. Three points block the shot.")


static func add_arm_actuators(th: ToHit, u: Unit, loc: int) -> void:
	if u.def.has_actuator(loc, "shoulder") and not u.has_working_actuator(loc, "shoulder"):
		th.add("shoulder hit", 4, "A damaged shoulder makes aiming that arm much harder.")
		return
	for a in ["upper_arm", "lower_arm"]:
		if u.def.has_actuator(loc, a) and not u.has_working_actuator(loc, a):
			th.add(a.replace("_", " ") + " hit", 1, "A damaged arm actuator throws off the aim.")


## Target movement modifier from hexes moved this turn.
static func target_movement_mod(hexes: int, jumped: bool = false) -> int:
	if jumped:
		return target_movement_mod(hexes) + 1
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


## Shut down, MechWarrior unconscious, or no MP left from damage (both legs
## gone), book p. 49. Heat alone taking MP to 0 doesn't count.
static func is_immobile(u: Unit) -> bool:
	return u.shutdown or not u.pilot.conscious or u.legs_destroyed() >= 2 \
			or (u.vehicle != null and (u.vehicle.immobile or u.vehicle.crew_stunned > 0))


## Standing in depth 1 water.
static func in_partial_cover(map: BattleMap, u: Unit) -> bool:
	var tile := map.get_tile(u.coord)
	return tile != null and tile.is_water() and tile.depth == 1 and not u.prone
