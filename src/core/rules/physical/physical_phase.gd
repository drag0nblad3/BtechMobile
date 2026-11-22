class_name PhysicalPhase
extends RefCounted
## Resolves declared physical attacks at the end of the Physical Attack Phase.
## Every attack is rolled (and its damage dealt) first; only then are 'Mechs
## moved by charges, death from above and pushes (book p. 76). Two 'Mechs
## that push each other successfully both stay put and both roll; a push at
## a 'Mech that pushed a third one fails (errata p. 83).


static func resolve(state: GameState, dice: Dice, emit: Callable) -> void:
	var steps: Array[Dictionary] = []
	for d in state.declared_physical:
		if d.has("target_hex"):
			BuildingMelee.resolve(state, emit, state.unit_by_id(d["attacker_id"]), d)
			continue
		if d["kind"] == "charge" or d["kind"] == "dfa":
			var step := ChargeResolve.resolve(state, dice, emit, d)
			if not step.is_empty():
				steps.append(step)
			continue
		if d["kind"] == "brush_off":
			BaBrushOff.resolve(state, dice, emit, d)
			continue
		var a := state.unit_by_id(d["attacker_id"])
		var t := state.unit_by_id(d["target_id"])
		var th: ToHit = d["to_hit"]
		if d["kind"] == "push" and PhysicalMods.pushing_other(state, t, a):
			emit.call(GameEvent.PHYSICAL, {"attacker_id": a.id, "target_id": t.id, "kind": "push",
					"limb": -1, "roll": 0, "need": th.target(), "hit": false, "damage": 0,
					"mods": th.mods, "why": "its target was pushing another 'Mech"})
			continue
		var roll := dice.roll_2d6()
		var need := th.target()
		var hit := roll >= need and need <= 12
		emit.call(GameEvent.PHYSICAL, {"attacker_id": a.id, "target_id": t.id,
				"kind": d["kind"], "limb": d["limb"], "roll": roll, "need": need,
				"hit": hit, "damage": d["damage"] if hit else 0, "mods": th.mods,
				"tsm": d.get("tsm", false)})
		if d["kind"] == "push":
			if hit:
				steps.append({"kind": "push", "attacker": a, "target": t,
						"dir": Hex.direction_to(a.coord, t.coord), "hit": true})
			continue
		var is_kick: bool = d["kind"] == "kick"
		if not hit:
			if is_kick:
				a.psr_pending.append({"reason": "missed a kick", "mod": 0})
			continue
		_strike(state, dice, emit, a, t, d)
		if is_kick:
			t.psr_pending.append({"reason": "was kicked", "mod": 0})
		elif d["kind"] == "club":
			t.psr_pending.append({"reason": "was clubbed", "mod": 0})
			if a.club == "tree":
				a.club = ""  # trees only last one hit
	state.declared_physical.clear()
	BuildingDamage.end_phase(state, dice, emit)
	for step in steps:
		if step["kind"] == "push":
			_push(state, dice, emit, step, steps)
		else:
			ChargeResolve.displace(state, dice, emit, step)


## Damage from a punch or kick, on the table the option chose.
static func _strike(state: GameState, dice: Dice, emit: Callable, a: Unit, t: Unit, d: Dictionary) -> void:
	var arc_id := FiringArc.arc(t.coord, t.facing, a.coord)
	var hl: Dictionary
	match String(d.get("table", "punch")):
		"kick":
			hl = HitTable.roll_kick(dice, arc_id, t.def.quad)
			hl["no_cover"] = true
			hl["kick_table"] = true
		"full":
			hl = HitTable.roll(dice, arc_id)
		_:
			hl = HitTable.roll_punch(dice, arc_id, t.def.quad)
	var dmg := WaterCombat.physical_damage(state.map, t, hl["loc"], d["damage"])
	WeaponFire.hit_with(state, dice, emit, t, arc_id, dmg, a.id, d["kind"], hl, Hex.INVALID, ["physical"])


static func _push(state: GameState, dice: Dice, emit: Callable, step: Dictionary, steps: Array[Dictionary]) -> void:
	var a: Unit = step["attacker"]
	var t: Unit = step["target"]
	t.psr_pending.append({"reason": "was pushed", "mod": 0})
	for other in steps:
		if other["kind"] == "push" and other["attacker"] == t and other["target"] == a:
			return  # pushed each other: nobody moves, both roll
	if a.destroyed or t.destroyed:
		return
	var from := t.coord
	if Displacement.push(state, dice, emit, t, step["dir"]):
		Displacement.move_to(state, emit, a, from)
