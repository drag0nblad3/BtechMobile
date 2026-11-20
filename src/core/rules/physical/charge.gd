class_name Charge
extends RefCounted
## Charges and death from above (DFA), declared at the end of a move into the
## hex next to an enemy that is straight ahead, resolved in the Physical
## Attack Phase. A 'Mech that charges or jumps on someone makes no weapon or
## other physical attacks that turn.
## Charge: target takes ceil(tons/10) x hexes moved, attacker takes
## ceil(target tons/10); both roll to stay up (+2). DFA: target takes
## ceil(tons/10) x 3 (punch table), attacker takes ceil(tons/5) to the legs
## (kick table) and rolls at +4; a missed DFA means the attacker falls.
## TODO(rules): to-hit modifiers, displacement chains, miss positions simplified.


## {to_hit, damage, self_damage, kind} for charging/jumping onto `t` from `a`'s
## current hex (after its move). to_hit.impossible explains why not.
static func option(state: GameState, a: Unit, t: Unit, kind: String) -> Dictionary:
	var th := ToHit.new()
	var out := {"kind": kind, "to_hit": th, "damage": 0, "self_damage": 0, "limb": -1}
	if t == null or t.destroyed or t.side == a.side:
		th.impossible = "No enemy target"
	elif Hex.distance(a.coord, t.coord) != 1 or FiringArc.wedge(a.coord, a.facing, t.coord) != 0:
		th.impossible = "The target must be in the hex directly in front of you"
	elif kind == "charge" and (a.move_mode == MoveMode.Kind.JUMP or a.hexes_moved < 1):
		th.impossible = "Charging needs at least one hex of walking or running"
	elif kind == "dfa" and a.move_mode != MoveMode.Kind.JUMP:
		th.impossible = "Death from above needs a jump"
	if th.impossible != "":
		return out
	th.add("Piloting", a.pilot.piloting, "Charges and death from above use piloting skill.")
	if kind == "charge":
		var diff := a.pilot.piloting - t.pilot.piloting
		if diff != 0:
			th.add("piloting difference", diff, "A better pilot on the receiving end can sidestep a charge.")
	var jumped := t.move_mode == MoveMode.Kind.JUMP
	var tm := ToHitCalc.target_movement_mod(t.hexes_moved, jumped)
	if tm > 0:
		th.add("target moved", tm, "A moving target is harder to slam into.")
	var tile := state.map.get_tile(t.coord)
	var tw := LineOfSight.woods_value(tile) if tile else 0
	if tw > 0:
		th.add("target in woods", tw, "Trees get in the way.")
	if t.shutdown or not t.pilot.conscious:
		th.add("target immobile", -4, "It can't get out of the way.")
	var tens := ceili(a.def.tonnage / 10.0)
	if kind == "charge":
		out["damage"] = tens * a.hexes_moved
		out["self_damage"] = ceili(t.def.tonnage / 10.0)
	else:
		out["damage"] = tens * 3
		out["self_damage"] = ceili(a.def.tonnage / 5.0)
	return out


static func resolve(state: GameState, dice: Dice, emit: Callable, d: Dictionary) -> void:
	var a := state.unit_by_id(d["attacker_id"])
	var t := state.unit_by_id(d["target_id"])
	var kind: String = d["kind"]
	var th: ToHit = d["to_hit"]
	var roll := dice.roll_2d6()
	var hit := roll >= th.target() and roll > 2
	emit.call(GameEvent.PHYSICAL, {"attacker_id": a.id, "target_id": t.id, "kind": kind,
			"limb": -1, "roll": roll, "need": th.target(), "hit": hit,
			"damage": d["damage"] if hit else 0, "mods": th.mods})
	if not hit:
		if kind == "dfa":
			a.psr_pending.append({"reason": "missed death from above", "auto_fall": true, "mod": 0})
		return
	var t_arc := FiringArc.arc(t.coord, t.facing, a.coord)
	for p in Damage.clusters(d["damage"], 5):
		var hl := HitTable.roll_punch(dice, t_arc) if kind == "dfa" else HitTable.roll(dice, t_arc)
		WeaponFire.hit_with(state, dice, emit, t, t_arc, p, a.id, kind, hl)
	for p in Damage.clusters(d["self_damage"], 5):
		var hl := HitTable.roll_kick(dice, FiringArc.FRONT) if kind == "dfa" else HitTable.roll(dice, FiringArc.FRONT)
		WeaponFire.hit_with(state, dice, emit, a, FiringArc.FRONT, p, a.id, kind + " (self)", hl)
	a.psr_pending.append({"reason": "made a " + ("charge" if kind == "charge" else "death from above"), "mod": 2 if kind == "charge" else 4})
	t.psr_pending.append({"reason": "was hit by a " + ("charge" if kind == "charge" else "death from above"), "mod": 2})
	var from := t.coord
	if Displacement.push(state, emit, t, Hex.direction_to(a.coord, t.coord)):
		Displacement.move_to(state, emit, a, from)
