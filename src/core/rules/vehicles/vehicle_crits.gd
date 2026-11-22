class_name VehicleCrits
extends RefCounted
## Combat vehicle critical hits: 2D6 on the struck location's table.
## TODO(rules): Total Warfare's Ground Combat Vehicle Critical Hits Table
## from general knowledge; malfunctions and turret jams last the game.

const TABLES := {
	VehicleLoc.FRONT: {6: "driver", 7: "malfunction", 8: "stabilizer", 9: "sensors",
			10: "commander", 11: "weapon", 12: "crew_killed"},
	VehicleLoc.LEFT: {7: "malfunction", 8: "crew_stunned", 9: "stabilizer", 10: "weapon",
			11: "engine", 12: "fuel"},
	VehicleLoc.REAR: {6: "malfunction", 8: "stabilizer", 9: "weapon", 10: "engine",
			11: "ammo", 12: "fuel"},
	VehicleLoc.TURRET: {6: "stabilizer", 7: "turret_locked", 8: "malfunction", 9: "turret_locked",
			10: "weapon", 11: "ammo", 12: "turret_off"},
}


## Rolls one critical hit on `loc` and applies it.
static func roll(dice: Dice, emit: Callable, u: Unit, loc: int) -> void:
	var r := dice.roll_2d6()
	var table: Dictionary = TABLES[VehicleLoc.LEFT if loc == VehicleLoc.RIGHT else loc]
	var kind: String = table.get(r, "none")
	var data := {"kind": "crit", "unit_id": u.id, "loc": loc, "roll": r, "effect": apply(u, loc, kind)}
	emit.call(GameEvent.VEHICLE, data)
	Damage.announce(emit, u)


## Applies a critical effect; returns what happened ("none" if nothing to hit).
static func apply(u: Unit, loc: int, kind: String) -> String:
	var v := u.vehicle
	match kind:
		"driver":
			v.driver_hit = true
			v.driving_mod += 2
		"commander":
			v.commander_hit = true
		"crew_stunned":
			v.crew_stunned = 2
		"stabilizer":
			v.stabilizers[loc] = true
		"sensors":
			v.sensor_hits += 1
		"malfunction", "weapon":
			var w := _weapon_in(u, loc)
			if w == null:
				return "none"
			if kind == "weapon":
				w.destroyed = true
			else:
				w.jammed = true
			return "%s:%s" % [kind, w.def.name]
		"turret_locked":
			v.turret_locked = true
		"turret_off":
			v.turret_lost = true
			v.turret_locked = true
			for w in u.weapons:
				if w.loc == VehicleLoc.TURRET:
					w.destroyed = true
		"engine":
			v.engine_hit = true
			v.immobile = true
		"fuel":
			if v.spec.engine == "fusion":
				v.engine_hit = true
				v.immobile = true
				return "engine"
			Damage.destroy_unit(u, "its fuel tank exploded")
		"ammo":
			if not u.ammo.any(func(b: AmmoBin) -> bool: return b.shots > 0):
				return "none"
			Damage.destroy_unit(u, "its ammunition exploded")
		"crew_killed":
			Damage.destroy_unit(u, "its crew was killed")
	return kind


static func _weapon_in(u: Unit, loc: int) -> MountedWeapon:
	for w in u.weapons:
		if w.loc == loc and not w.destroyed and not w.jammed:
			return w
	return null
