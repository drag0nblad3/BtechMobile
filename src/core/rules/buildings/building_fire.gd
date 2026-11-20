class_name BuildingFire
extends RefCounted
## Shooting a building hex instead of a 'Mech. Buildings can't dodge (-4);
## every hit lowers the building's CF, and at 0 it collapses.
## TODO(rules): verify the -4; no secondary-target cost; a 'Mech inside is
## not hurt by these shots until the building comes down.


## [{index, weapon, to_hit}] for every weapon against the building at `c`.
static func options(state: GameState, attacker: Unit, c: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in attacker.weapons.size():
		out.append({"index": i, "weapon": attacker.weapons[i],
				"to_hit": to_hit(state, attacker, attacker.weapons[i], c)})
	return out


static func to_hit(state: GameState, attacker: Unit, w: MountedWeapon, c: Vector2i) -> ToHit:
	var th := ToHit.new()
	var tile := state.map.get_tile(c)
	if tile == null or tile.building == null:
		th.impossible = "No building there"
		return th
	if not attacker.can_fire(w):
		th.impossible = "%s can't fire" % w.def.name
		return th
	var arc_id := FiringArc.arc(attacker.coord, FiringArc.weapon_facing(attacker, w.loc), c)
	if not FiringArc.weapon_covers(w.loc, w.rear, arc_id):
		th.impossible = "The building is in your %s arc; %s can't point there" % [FiringArc.NAMES[arc_id], w.label()]
		return th
	var los := LineOfSight.check_hex(state.map, attacker, c, tile.level + tile.building.height)
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
	if br == WeaponDef.Bracket.MEDIUM:
		th.add("medium range", 2, "%d hexes is medium range for %s." % [dist, w.def.name])
	elif br == WeaponDef.Bracket.LONG:
		th.add("long range", 4, "%d hexes is long range for %s." % [dist, w.def.name])
	if w.def.min_range > 0 and dist <= w.def.min_range:
		th.add("minimum range", w.def.min_range - dist + 1, "Inside %s's minimum range." % w.def.name)
	ToHitCalc.add_attacker_conditions(th, attacker, los)
	if Location.is_arm(w.loc):
		ToHitCalc.add_arm_actuators(th, attacker, w.loc)
	th.add("building", -4, "A building can't move or dodge: -4.")
	return th


## Fires one declared shot at a building.
static func resolve(state: GameState, dice: Dice, emit: Callable, attacker: Unit,
		w: MountedWeapon, c: Vector2i, th: ToHit) -> void:
	var tile := state.map.get_tile(c)
	var data := {"attacker_id": attacker.id, "target_id": -1, "target_hex": c, "weapon": w.def.name,
			"weapon_id": w.def.id, "roll": 0, "need": th.target(), "hit": false, "mods": th.mods, "missiles": 0}
	if w.def.uses_ammo() and not attacker.use_ammo(w.def):
		data["no_ammo"] = true
		emit.call(GameEvent.WEAPON_FIRED, data)
		return
	w.fired = true
	attacker.heat_generated += w.def.heat
	data["roll"] = dice.roll_2d6()
	data["hit"] = data["roll"] >= th.target() and data["roll"] > 2 and tile != null and tile.building != null
	var dmg := w.def.damage
	if data["hit"] and w.def.is_cluster():
		data["missiles"] = ClusterTable.hits(w.def.missiles, dice.roll_2d6())
		dmg = data["missiles"] * w.def.damage
	emit.call(GameEvent.WEAPON_FIRED, data)
	if not data["hit"]:
		return
	var b := tile.building
	b.cf = maxi(0, b.cf - dmg)
	emit.call(GameEvent.BUILDING, {"kind": "shot", "coord": c, "name": b.type.name, "damage": dmg, "cf": b.cf})
	if b.cf == 0:
		BuildingRules.collapse(state, dice, emit, tile)
