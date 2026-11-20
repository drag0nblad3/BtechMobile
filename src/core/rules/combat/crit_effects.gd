class_name CritEffects
extends RefCounted
## What a critical hit on each kind of slot does. Returns a short description.

const ENGINE_KILL := 3
const GYRO_KILL := 2


static func apply(state: GameState, dice: Dice, emit: Callable, u: Unit, loc: int,
		slot: CritSlot) -> String:
	if u.flooded.get(loc, false) and slot.kind != CritSlot.Kind.AMMO:
		return "already flooded: no further effect"
	match slot.kind:
		CritSlot.Kind.ENGINE:
			u.engine_hits += 1
			if u.engine_hits >= ENGINE_KILL:
				Damage.destroy_unit(u, "engine destroyed")
				return "engine destroyed"
			return "engine hit: +5 heat every turn"
		CritSlot.Kind.GYRO:
			u.gyro_hits += 1
			if u.gyro_hits >= GYRO_KILL:
				u.psr_pending.append({"reason": "gyro destroyed", "auto_fall": true, "mod": 0})
				return "gyro destroyed: falls and can't stand"
			u.psr_pending.append({"reason": "gyro hit", "mod": 0})
			return "gyro hit: +2 to piloting rolls"
		CritSlot.Kind.COCKPIT:
			u.pilot.hits = Pilot.MAX_HITS
			Damage.destroy_unit(u, "cockpit destroyed")
			return "cockpit destroyed"
		CritSlot.Kind.SENSORS:
			u.sensor_hits += 1
			return "sensors hit: +2 to hit" if u.sensor_hits < 2 else "sensors destroyed: can't fire"
		CritSlot.Kind.LIFE_SUPPORT:
			return "life support hit: pilot hurt at heat 10+ or under water"
		CritSlot.Kind.ACTUATOR:
			return _actuator(u, loc, slot)
		CritSlot.Kind.WEAPON:
			u.weapons[slot.ref].destroyed = true
			return "%s destroyed" % slot.name
		CritSlot.Kind.AMMO:
			var bin := u.ammo[slot.ref]
			if bin.explosion_damage() > 0:
				AmmoExplosion.explode(state, dice, emit, u, bin)
				return "ammo explodes"
			bin.destroyed = true
			return "empty ammo bin destroyed"
		CritSlot.Kind.HEAT_SINK:
			if not u.lose_heat_sink(slot):
				return "part of a heat sink already destroyed"
			return "heat sink destroyed: -%d heat dissipation" % u.def.heat_per_sink()
		CritSlot.Kind.JUMP_JET:
			return "jump jet destroyed"
	return "no effect"


static func _actuator(u: Unit, loc: int, slot: CritSlot) -> String:
	var nice := slot.name.replace("_", " ")
	if Location.is_leg(loc):
		u.psr_pending.append({"reason": "%s hit" % nice, "mod": 0, "leg": loc})
		return "%s hit: slower, piloting roll" % nice
	return "%s hit: arm weapons and punches less accurate" % nice
