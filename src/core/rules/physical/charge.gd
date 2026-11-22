class_name Charge
extends RefCounted
## Charges and death from above (DFA), book pp. 78-81. Declared at the end of
## a move into the hex next to an enemy straight ahead (with MP left to enter
## its hex), resolved in the Physical Attack Phase by `ChargeResolve`. A
## 'Mech that charges or jumps on someone makes no weapon attacks that turn.
## To hit: piloting plus the piloting difference (an immobile target counts
## as piloting 4), plus the usual movement modifiers (+3 for the jump). A
## charge also counts woods but not partial cover; a DFA ignores terrain.
## Charge damage: ceil(tons / 5 x (attacker's target movement modifier + 1)),
## counting the move into the target's hex; the attacker takes ceil(target
## tons / 10). DFA: ceil(tons / 10 x 3) to the target, ceil(tons / 5) back.


## Damage a charge does after entering `hexes` hexes, the target hex included.
static func charge_damage(a: Unit, hexes: int) -> int:
	return ceili(a.def.tonnage / 5.0 * (ToHitCalc.target_movement_mod(hexes) + 1))


static func dfa_damage(a: Unit) -> int:
	return ceili(a.def.tonnage / 10.0 * 3)


## {to_hit, damage, self_damage, kind} for charging/jumping onto `t` from `a`'s
## current hex (after its move). to_hit.impossible explains why not.
static func option(state: GameState, a: Unit, t: Unit, kind: String) -> Dictionary:
	var th := ToHit.new()
	var out := {"kind": kind, "to_hit": th, "damage": 0, "self_damage": 0, "limb": -1}
	var dl := PhysicalMods.level_diff(state, a, t) if t != null else 0
	var tile := state.map.get_tile(a.coord)
	if t == null or t.destroyed or t.side == a.side:
		th.impossible = "No enemy target"
	elif a.asset != null or t.asset != null:
		th.impossible = "Assets can't charge or be charged (p. 145)"
	elif a.vehicle != null or t.vehicle != null or a.ba != null or t.ba != null:
		th.impossible = "Charges by or against vehicles and battle armor aren't in the game yet"  # TODO(rules)
	elif Hex.distance(a.coord, t.coord) != 1 or FiringArc.wedge(a.coord, a.facing, t.coord) != 0:
		th.impossible = "The target must be in the hex directly in front of you"
	elif kind == "charge" and a.move_mode == MoveMode.Kind.JUMP:
		th.impossible = "Charging needs walking or running; jumping onto it is death from above"
	elif kind == "charge" and (t.prone or absi(dl) > 1):
		th.impossible = "Can't charge a 'Mech that is down or more than a level away"
	elif kind == "dfa" and a.move_mode != MoveMode.Kind.JUMP:
		th.impossible = "Death from above needs a jump"
	elif kind == "dfa" and tile != null and tile.is_water() and tile.depth >= 2:
		th.impossible = "Can't jump on anyone from deep water"
	elif WaterCombat.physical_blocked(state.map, a, t, kind) != "":
		th.impossible = WaterCombat.physical_blocked(state.map, a, t, kind)
	elif PhysicalMods.charging(state, t):
		th.impossible = "It is still moving: it is charging someone itself"
	elif PhysicalMods.shoved_already(state, t):
		th.impossible = "Someone is already charging or pushing it this turn"
	if th.impossible != "":
		return out
	th.add("Piloting", a.pilot.piloting, "Charges and death from above use piloting skill.")
	var tp := 4 if ToHitCalc.is_immobile(t) else t.pilot.piloting
	if a.pilot.piloting != tp:
		th.add("piloting difference", a.pilot.piloting - tp,
				"Your piloting minus the target's: a better pilot on the receiving end can sidestep.")
	ToHitCalc.add_movement(th, a, t)
	if kind == "charge":
		var ttile := state.map.get_tile(t.coord)
		var tw := LineOfSight.woods_value(ttile) if ttile else 0
		if tw > 0:
			th.add("target in woods", tw, "Trees get in the way.")
	if t.prone:
		th.add("target prone", -2, "Landing on a 'Mech that is down is easier: -2.")
	if ToHitCalc.is_immobile(t):
		th.add("target immobile", -4, "It can't get out of the way.")
	if kind == "charge":
		out["damage"] = charge_damage(a, a.hexes_moved + 1)
		out["self_damage"] = ceili(t.def.tonnage / 10.0)
	else:
		out["damage"] = dfa_damage(a)
		out["self_damage"] = ceili(a.def.tonnage / 5.0)
	return out


## Enough MP left after reaching `at` to enter the target's hex `to`?
static func has_mp(state: GameState, at: Vector2i, to: Vector2i, mode: int, mp_left: int) -> bool:
	if mode == MoveMode.Kind.JUMP:
		return mp_left >= 1
	var need := MoveCost.enter_cost(state.map, at, to, mode)
	return need != MoveCost.PROHIBITED and mp_left >= need


## Records a charge/DFA if legal and `mp_left` covers the target hex; the
## unit then skips weapon and physical attacks. Its movement counts the
## target hex too.
static func declare(state: GameState, emit: Callable, unit: Unit, t: Unit, mp_left: int) -> void:
	if t == null:
		return
	var kind := "dfa" if unit.move_mode == MoveMode.Kind.JUMP else "charge"
	if not has_mp(state, unit.coord, t.coord, unit.move_mode, mp_left):
		return
	var opt := option(state, unit, t, kind)
	if not opt["to_hit"].possible():
		return
	opt["attacker_id"] = unit.id
	opt["target_id"] = t.id
	state.declared_physical.append(opt)
	unit.has_fired = true
	unit.has_physical = true
	unit.hexes_moved += 1
	emit.call(GameEvent.CHARGE_DECLARED, {"unit_id": unit.id, "target_id": t.id, "kind": kind,
			"need": opt["to_hit"].target()})
