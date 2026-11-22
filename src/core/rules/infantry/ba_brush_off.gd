class_name BaBrushOff
extends RefCounted
## A 'Mech swats at battle armor swarming it, as its physical attack: each
## arm, Piloting +4 (plus the punch modifiers for a missing hand or arm
## actuators). A hit does the arm's punch damage to the squad and knocks it
## off into the hex; a miss punches the 'Mech itself (Punch table, front).
## TODO(rules): Total Warfare via MegaMek's brush-off.

const MOD := 4


static func options(state: GameState, a: Unit, t: Unit) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if a.def.quad:
		return out
	for arm in [Location.LA, Location.RA]:
		var th := ToHit.new()
		var dmg := ceili(a.def.tonnage / 10.0)
		if a.is_location_out(arm) or not a.has_working_actuator(arm, "shoulder"):
			th.impossible = "%s can't reach them" % Location.name_of(arm)
		elif PhysicalMods.limb_fired(a, arm):
			th.impossible = "That arm fired a weapon this turn"
		elif a.carry_arm == arm:
			th.impossible = "That arm is carrying the objective"
		elif a.prone:
			th.impossible = "It can't swat at them lying down"
		else:
			th.add("piloting", a.pilot.piloting, "Swatting troopers off your own hull uses Piloting.")
			th.add("brush off", MOD, "Small targets clinging to you are hard to hit: +4.")
			if t.def.battle_armor.magnets:
				th.add("magnetic claws", 1, "Magnets hold them on: +1.")
			if not a.has_working_actuator(arm, "hand"):
				th.add("no hand", 1, "No working hand: +1.")
			for act in ["upper_arm", "lower_arm"]:
				if not a.has_working_actuator(arm, act):
					th.add("no " + act.replace("_", " "), 2, "A broken arm actuator: +2, half damage.")
					@warning_ignore("integer_division")
					dmg = dmg / 2
		out.append({"kind": "brush_off", "limb": arm, "to_hit": th, "damage": dmg, "table": ""})
	return out


static func resolve(state: GameState, dice: Dice, emit: Callable, d: Dictionary) -> void:
	var a := state.unit_by_id(d["attacker_id"])
	var t := state.unit_by_id(d["target_id"])
	var th: ToHit = d["to_hit"]
	var roll := dice.roll_2d6()
	var hit := roll >= th.target()
	emit.call(GameEvent.PHYSICAL, {"attacker_id": a.id, "target_id": t.id, "kind": "brush_off",
			"limb": d["limb"], "roll": roll, "need": th.target(), "hit": hit,
			"damage": d["damage"] if hit else 0, "mods": th.mods})
	if not hit:
		var hl := HitTable.roll_punch(dice, FiringArc.FRONT, a.def.quad)
		WeaponFire.hit_with(state, dice, emit, a, FiringArc.FRONT, d["damage"], a.id, "its own swat", hl, Hex.INVALID, ["physical"])
		return
	if BaSwarm.on(t) != a.id:
		return  # already knocked off by the other arm
	BaDamage.take(dice, emit, t, d["damage"], a.id, "brush off")
	t.ba.swarming = -1
	if not t.destroyed:
		emit.call(GameEvent.TRANSPORT, {"unit_id": t.id, "carrier_id": a.id, "kind": "brushed"})
