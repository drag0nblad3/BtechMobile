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
			var w := u.weapons[slot.ref]
			if AutocannonCrit.absorb(w):
				return "%s hit: autocannons survive the first critical hit" % slot.name
			w.destroyed = true
			if w.def.explodes and not w.exploded:
				ComponentExplosion.explode(state, dice, emit, u, w, loc)
				return "%s explodes" % slot.name
			return "%s destroyed" % slot.name
		CritSlot.Kind.AMMO:
			var bin := u.ammo[slot.ref]
			if bin.explosion_damage() > 0:
				AmmoExplosion.explode(state, dice, emit, u, bin)
				return "ammo explodes"
			bin.destroyed = true
			return "ammo bin destroyed (%s)" % ("empty" if bin.weapon.ammo_explodes else "doesn't explode")
		CritSlot.Kind.HEAT_SINK:
			if not u.lose_heat_sink(slot):
				return "part of a heat sink already destroyed"
			return "heat sink destroyed: -%d heat dissipation" % u.def.heat_per_sink()
		CritSlot.Kind.MELEE:
			u.melee_lost[slot.ref] = true
			return "%s destroyed" % slot.name.to_lower()
		CritSlot.Kind.ARTEMIS:
			u.weapons[slot.ref].artemis_lost = true
			return "Artemis IV fire control destroyed: no cluster bonus"
		CritSlot.Kind.ECM:
			u.ecm_lost = true
			return "ECM suite destroyed"
		CritSlot.Kind.MASC:
			return "MASC destroyed: no more bursts of speed"
		CritSlot.Kind.SUPERCHARGER:
			return "supercharger destroyed"
		CritSlot.Kind.C3:
			return "C3 computer destroyed: it drops out of its network" + (", and the network goes down with its Master" if slot.name == "C3 Master" else "")
		CritSlot.Kind.GEAR:
			return "%s destroyed" % slot.name
		CritSlot.Kind.PROBE:
			u.probe_lost = true
			return "active probe destroyed"
		CritSlot.Kind.TARGETING:
			u.tc_lost = true
			return "targeting computer destroyed: no more -1 to hit"
		CritSlot.Kind.JUMP_JET:
			return "jump jet destroyed"
	return "no effect"


static func _actuator(u: Unit, loc: int, slot: CritSlot) -> String:
	var nice := slot.name.replace("_", " ")
	if Location.is_leg_of(u.def, loc):
		u.psr_pending.append({"reason": "%s hit" % nice, "mod": 0, "leg": loc})
		return "%s hit: slower, piloting roll" % nice
	return "%s hit: arm weapons and punches less accurate" % nice
