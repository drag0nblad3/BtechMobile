class_name PhysicalPhase
extends RefCounted
## Resolves declared physical attacks at the end of the Physical Attack Phase.


static func resolve(state: GameState, dice: Dice, emit: Callable) -> void:
	for d in state.declared_physical:
		if d["kind"] == "charge" or d["kind"] == "dfa":
			Charge.resolve(state, dice, emit, d)
			continue
		if d["kind"] == "push":
			_push(state, dice, emit, d)
			continue
		var a := state.unit_by_id(d["attacker_id"])
		var t := state.unit_by_id(d["target_id"])
		var th: ToHit = d["to_hit"]
		var roll := dice.roll_2d6()
		var hit := roll >= th.target()
		emit.call(GameEvent.PHYSICAL, {"attacker_id": a.id, "target_id": t.id,
				"kind": d["kind"], "limb": d["limb"], "roll": roll, "need": th.target(),
				"hit": hit, "damage": d["damage"] if hit else 0, "mods": th.mods})
		var is_kick: bool = d["kind"] == "kick"
		if not hit:
			if is_kick:
				a.psr_pending.append({"reason": "missed a kick", "mod": 0})
			continue
		var arc_id := FiringArc.arc(t.coord, t.facing, a.coord)
		var hl := HitTable.roll_kick(dice, arc_id) if is_kick else HitTable.roll_punch(dice, arc_id)
		WeaponFire.hit_with(state, dice, emit, t, arc_id, d["damage"], a.id, d["kind"], hl)
		if is_kick:
			t.psr_pending.append({"reason": "was kicked", "mod": 0})
	state.declared_physical.clear()


static func _push(state: GameState, dice: Dice, emit: Callable, d: Dictionary) -> void:
	var a := state.unit_by_id(d["attacker_id"])
	var t := state.unit_by_id(d["target_id"])
	var th: ToHit = d["to_hit"]
	var roll := dice.roll_2d6()
	var hit := roll >= th.target()
	emit.call(GameEvent.PHYSICAL, {"attacker_id": a.id, "target_id": t.id, "kind": "push",
			"limb": -1, "roll": roll, "need": th.target(), "hit": hit, "damage": 0, "mods": th.mods})
	if hit:
		var from := t.coord
		t.psr_pending.append({"reason": "was pushed", "mod": 0})
		if Displacement.push(state, dice, emit, t, Hex.direction_to(a.coord, t.coord)):
			Displacement.move_to(state, emit, a, from)
