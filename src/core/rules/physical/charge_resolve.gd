class_name ChargeResolve
extends RefCounted
## Rolls a declared charge or death from above and deals its damage. Moving
## the 'Mechs waits until every physical attack of the phase is rolled
## (book p. 76), so this returns what `PhysicalPhase` should move.
## - Charge hit: target pushed straight on, attacker takes its hex, both roll
##   at +2. A miss leaves both where they are.
## - DFA hit: same, target pushed to the nearest open hexside (destroyed if
##   none). Prone target: damage on the Rear column of the full table.
## - DFA miss: target steps to an open adjacent hex, the attacker lands in
##   its hex and falls 2 levels onto its back (destroyed if nowhere to go).
##   A DFA can't be called off (p. 80): it misses without a roll if the
##   attacker failed a piloting roll in the Weapon Attack Phase (it doesn't
##   fall then), is prone, or its MechWarrior is unconscious.
## TODO(rules): a DFA attacker knocked prone by an automatic fall (no roll)
## is treated like one that failed its roll.


## Returns {kind, attacker, target, dir, hit} for the displacement step, or {}.
static func resolve(state: GameState, dice: Dice, emit: Callable, d: Dictionary) -> Dictionary:
	var a := state.unit_by_id(d["attacker_id"])
	var t := state.unit_by_id(d["target_id"])
	var kind: String = d["kind"]
	if a.destroyed or t.destroyed:
		return {}
	var why := forced_miss(a, d)
	if kind == "charge" and (why != "" or t.prone):
		return {}  # a charge simply doesn't happen
	var th: ToHit = d["to_hit"]
	var roll := dice.roll_2d6() if why == "" else 0
	var need := th.target()
	var hit := why == "" and roll >= need and need <= 12
	emit.call(GameEvent.PHYSICAL, {"attacker_id": a.id, "target_id": t.id, "kind": kind,
			"limb": -1, "roll": roll, "need": need, "hit": hit, "why": why,
			"damage": d["damage"] if hit else 0, "mods": th.mods})
	var dir := Hex.direction_to(a.coord, t.coord)
	var step := {"kind": kind, "attacker": a, "target": t, "dir": dir, "hit": hit}
	if not hit:
		return step if kind == "dfa" else {}
	var t_arc := FiringArc.arc(t.coord, t.facing, a.coord)
	var dfa_prone := kind == "dfa" and t.prone
	for p in Damage.clusters(d["damage"], 5):
		var hl: Dictionary
		if dfa_prone:
			hl = HitTable.roll(dice, FiringArc.REAR)
		elif kind == "dfa":
			hl = HitTable.roll_punch(dice, t_arc)
		else:
			hl = HitTable.roll(dice, t_arc)
			hl["no_cover"] = true
			hl["charge"] = true
		WeaponFire.hit_with(state, dice, emit, t, FiringArc.REAR if dfa_prone else t_arc, p, a.id, kind, hl)
	for p in Damage.clusters(d["self_damage"], 5):
		var hl := HitTable.roll_kick(dice, FiringArc.FRONT) if kind == "dfa" else HitTable.roll(dice, FiringArc.FRONT)
		hl["no_cover"] = true
		WeaponFire.hit_with(state, dice, emit, a, FiringArc.FRONT, p, a.id, kind + " (self)", hl)
	return step


## Why a declared DFA (or charge) can't be rolled, or "".
static func forced_miss(a: Unit, d: Dictionary) -> String:
	if d.get("failed_psr", false):
		return "it lost its footing before the jump"
	if a.prone:
		return "it is on the ground"
	if not a.pilot.conscious:
		return "its MechWarrior is unconscious"
	return ""


## Moves the 'Mechs after the phase's attacks. `step` comes from resolve().
static func displace(state: GameState, dice: Dice, emit: Callable, step: Dictionary) -> void:
	var a: Unit = step["attacker"]
	var t: Unit = step["target"]
	var name := "charge" if step["kind"] == "charge" else "death from above"
	var from := t.coord
	if step["kind"] == "charge":
		if t.destroyed or Displacement.push(state, dice, emit, t, step["dir"]):
			if not a.destroyed:
				Displacement.move_to(state, emit, a, from)
		_rolls(a, t, name)
		return
	var moved := t.destroyed or Displacement.push_nearest(state, dice, emit, t, step["dir"])
	if not moved:
		var victim := t if step["hit"] else a
		Damage.destroy_unit(victim, "nowhere to land")
		Damage.announce(emit, victim)
		if victim == t and not a.destroyed:
			Displacement.move_to(state, emit, a, from)
		return
	if not a.destroyed:
		Displacement.move_to(state, emit, a, from)
	if step["hit"]:
		_rolls(a, t, name, Wind.dfa_fall_levels(state))
	elif not a.destroyed:
		Fall.fall(state, dice, emit, a, 2 + Wind.dfa_fall_levels(state), "missed a death from above", FiringArc.REAR)


## `fall_levels`: extra levels if the attacker falls (a death from above in the wind).
static func _rolls(a: Unit, t: Unit, name: String, fall_levels := 0) -> void:
	if not a.prone:
		a.psr_pending.append({"reason": "made a " + name, "mod": 2, "fall_levels": fall_levels})
	if not t.prone and not t.destroyed:
		t.psr_pending.append({"reason": "was hit by a " + name, "mod": 2})
