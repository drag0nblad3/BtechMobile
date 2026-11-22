class_name ApolloSaturation
extends RefCounted
## Apollo saturation mode (book p. 197): the linked MRM launcher fires at a
## hex (here: the hex of the unit you pick) as an area-effect attack. No
## target movement or immobile modifiers; on a hit the Cluster Hits roll has
## no MRM -1, and a third of the missiles (rounded) is AE damage to every unit
## in the hex, friend or foe, and to a building there. AMS in the hex cuts the
## roll as usual. Fully submerged units are never hit.
## TODO(rules): damage is applied in 5-point groups; units on a roof are hit
## too; the bot never uses saturation; a miss does nothing (no scatter).

const MODE := "saturation"
const GROUP := 5


static func modes(w: MountedWeapon) -> Array[String]:
	var out: Array[String] = [""]
	if Apollo.working(w):
		out.append(MODE)
	return out


static func on(w: MountedWeapon) -> bool:
	return w.mode == MODE and Apollo.working(w)


## To-hit for a saturation attack on hex `c`.
static func to_hit(state: GameState, attacker: Unit, w: MountedWeapon, c: Vector2i) -> ToHit:
	var th := ToHit.new()
	var tile := state.map.get_tile(c)
	if tile == null:
		th.impossible = "No hex there"
		return th
	var arc_id := FiringArc.fire_arc(attacker.coord, FiringArc.weapon_facing(attacker, w.loc), c)
	if not FiringArc.weapon_covers(w.loc, ArmFlip.rear(attacker, w), arc_id, attacker.def.quad):
		th.impossible = "The hex is in your %s arc; %s can't point there" % [FiringArc.NAMES[arc_id], w.label()]
		return th
	var los := LineOfSight.check_hex(state.map, attacker, c, tile.level + 1)
	if los["blocked"]:
		th.impossible = "No line of sight (%s)" % los["reason"]
		return th
	var dist := Hex.distance(attacker.coord, c)
	var br := w.def.bracket(dist)
	if br == WeaponDef.Bracket.OUT:
		th.impossible = "Out of range (%d hexes, max %d)" % [dist, w.def.long_range]
		return th
	th.add("Gunnery", attacker.pilot.gunnery, "Your MechWarrior's gunnery skill is the base number.")
	ToHitCalc.add_attacker_movement(th, attacker)
	LowVisibility.add(th, state, attacker)
	if br == WeaponDef.Bracket.MEDIUM:
		th.add("medium range", 2, "%d hexes is medium range for %s." % [dist, w.def.name])
	elif br == WeaponDef.Bracket.LONG:
		th.add("long range", 4, "%d hexes is long range for %s." % [dist, w.def.name])
	ToHitCalc.add_attacker_conditions(th, attacker, los)
	if Location.is_arm_of(attacker.def, w.loc):
		ToHitCalc.add_arm_actuators(th, attacker, w.loc)
	th.add("saturation (hex)", w.def.to_hit_at(br), "Saturation fire aims at the hex, so the target's movement doesn't count.")
	return th


## Units the blast reaches in hex `c`.
static func caught(state: GameState, c: Vector2i) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in state.units:
		if u.coord == c and not u.destroyed and u.carrier_id() < 0 \
				and not EndPhase.submerged(state, u):
			out.append(u)
	return out


static func resolve(state: GameState, dice: Dice, emit: Callable, attacker: Unit, w: MountedWeapon,
		c: Vector2i, th: ToHit) -> void:
	var shots := WeaponFire.take_shots(attacker, w)
	var data := {"attacker_id": attacker.id, "target_id": -1, "target_hex": c, "weapon": w.def.name,
			"weapon_id": w.def.id, "roll": 0, "need": th.target(), "hit": false, "mods": th.mods,
			"missiles": 0, "target_noun": "hex", "saturation": true}
	if shots == 0:
		data["no_ammo"] = true
		emit.call(GameEvent.WEAPON_FIRED, data)
		return
	w.fired = true
	attacker.heat_generated += w.def.heat
	data["roll"] = dice.roll_2d6()
	data["hit"] = data["roll"] >= th.target()
	if not data["hit"]:
		emit.call(GameEvent.WEAPON_FIRED, data)
		return
	var units := caught(state, c)
	var ams := false
	for u in units:
		var a := AntiMissile.engaging(u, attacker, w)
		if a != null and AntiMissile.engage(u, a):
			ams = true
			break
	var r := dice.roll_2d6()
	var n := ClusterTable.hits(w.def.missiles, r + (AntiMissile.CLUSTER_MOD if ams else 0))
	var dmg := roundi(n / 3.0)
	data.merge({"missiles": n, "cluster_roll": r, "ams": ams, "saturation_damage": dmg})
	emit.call(GameEvent.WEAPON_FIRED, data)
	if dmg <= 0:
		return
	for u in units:
		var arc_id := FiringArc.arc(u.coord, u.facing, attacker.coord)
		var left := dmg
		while left > 0 and not u.destroyed:
			WeaponFire.hit_with(state, dice, emit, u, arc_id, mini(GROUP, left), attacker.id, w.def.name, {}, Hex.INVALID, ["AE"])
			left -= GROUP
	var tile := state.map.get_tile(c)
	if tile != null and tile.building != null:
		emit.call(GameEvent.BUILDING, {"kind": "shot", "coord": c, "name": tile.building.type.name,
				"damage": dmg, "unit_id": attacker.id})
		BuildingDamage.add(state, attacker.id, c, dmg)
