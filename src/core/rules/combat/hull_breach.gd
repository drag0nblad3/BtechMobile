class_name HullBreach
extends RefCounted
## Hull breaches (book p. 127). Each time a location under water takes
## damage, roll 2D6: 2-4 floods it. A location under water with no armor left
## (front or rear for a torso) floods at once, now or whenever it goes under.
## Everything in a flooded location stops working as if destroyed, but
## nothing explodes and the slots still soak critical hits; a flooded leg
## counts as a destroyed leg, a flooded side torso floods its arm too, and
## ammo stays explosive. Flooding lasts after leaving the water.

const FLOODS_ON := 4


## Breach checks for the submerged locations that `steps` damaged.
static func after_damage(state: GameState, dice: Dice, emit: Callable, u: Unit,
		steps: Array[Dictionary]) -> void:
	var checked := {}
	for st: Dictionary in steps:
		var loc: int = st["loc"]
		if u.destroyed or checked.has(loc) or int(st["armor"]) + int(st["structure"]) <= 0:
			continue
		checked[loc] = true
		if u.is_location_out(loc) or not WaterCombat.submerged(state.map, u, loc):
			continue
		var roll := 0 if bare(u, loc) else dice.roll_2d6()
		if roll <= FLOODS_ON:
			flood(state, emit, u, loc, roll)
		else:
			emit.call(GameEvent.HULL_BREACH, {"unit_id": u.id, "loc": loc, "roll": roll,
					"flooded": false, "effects": []})


## Floods any bare location now under water (after moving or falling).
static func check_exposed(state: GameState, emit: Callable, u: Unit) -> void:
	for loc in Location.COUNT:
		if u.destroyed:
			return
		if not u.is_location_out(loc) and bare(u, loc) and WaterCombat.submerged(state.map, u, loc):
			flood(state, emit, u, loc)


static func bare(u: Unit, loc: int) -> bool:
	return u.armor[loc] <= 0 or (Location.HAS_REAR.has(loc) and u.rear_armor[loc] <= 0)


## `roll`: the breach roll, 0 for a bare location, -1 when spreading from a torso.
static func flood(state: GameState, emit: Callable, u: Unit, loc: int, roll := 0) -> void:
	if u.flooded.get(loc, false):
		return
	u.flooded[loc] = true
	var effects: Array[String] = []
	for s: CritSlot in u.slots[loc]:
		if not s.hit:
			var e := _disable(u, s)
			if e != "":
				effects.append(e)
	emit.call(GameEvent.HULL_BREACH, {"unit_id": u.id, "loc": loc, "roll": roll,
			"flooded": true, "effects": effects})
	if u.engine_hits >= CritEffects.ENGINE_KILL:
		Damage.destroy_unit(u, "engine flooded")
	Damage.announce(emit, u)
	var arm := Location.arm_of_torso(loc)
	if arm >= 0 and not u.destroyed and not u.is_location_destroyed(arm):
		flood(state, emit, u, arm, -1)


static func _disable(u: Unit, s: CritSlot) -> String:
	match s.kind:
		CritSlot.Kind.ENGINE:
			u.engine_hits += 1
			return "engine"
		CritSlot.Kind.GYRO:
			u.gyro_hits += 1
			if u.gyro_hits == CritEffects.GYRO_KILL:
				u.psr_pending.append({"reason": "gyro flooded", "auto_fall": true, "mod": 0})
			return "gyro"
		CritSlot.Kind.COCKPIT:
			u.pilot.hits = Pilot.MAX_HITS
			u.pilot.conscious = false
			Damage.destroy_unit(u, "cockpit flooded")
			return "cockpit"
		CritSlot.Kind.SENSORS:
			u.sensor_hits += 1
			return "sensors"
		CritSlot.Kind.LIFE_SUPPORT:
			s.hit = true
			return "life support"
		CritSlot.Kind.HEAT_SINK:
			u.lose_heat_sink(s)
			return "heat sink"
		CritSlot.Kind.WEAPON:
			u.weapons[s.ref].destroyed = true
			return s.name
	return ""
