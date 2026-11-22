class_name Fall
extends RefCounted
## A 'Mech falls (book p. 115): it ends up prone with the same facing. Roll
## 1D6: on a 1 the damage hits the rear, otherwise the front. Damage is
## ceil(tons / 10) x (levels fallen + 1) in 5-point groups, halved (round
## down) in depth 1+ water, then times the gravity (Gravity). Then the seatbelt check (p. 117): piloting + 1
## per level fallen, no other modifiers; failure, an immobile 'Mech or a
## target over 12 means 1 MechWarrior hit.


static func damage_for(u: Unit, levels: int) -> int:
	return ceili(u.def.tonnage / 10.0) * (levels + 1)


## `side` forces the side hit (FiringArc.REAR for a missed death from above).
static func fall(state: GameState, dice: Dice, emit: Callable, u: Unit, levels: int,
		reason: String, side: int = -1) -> void:
	levels = Avalanche.slide(state, dice, emit, u, levels)
	if side < 0:
		side = FiringArc.REAR if dice.d6() == 1 else FiringArc.FRONT
	u.prone = true
	var total := damage_for(u, levels)
	var tile := state.map.get_tile(u.coord)
	var in_water := tile != null and tile.is_water() and tile.depth >= 1 and not u.on_bridge
	if in_water:
		@warning_ignore("integer_division")
		total = total / 2
	total = Gravity.scale(total, state.conditions)
	emit.call(GameEvent.FALL, {"unit_id": u.id, "damage": total, "levels": levels,
			"reason": reason, "facing": u.facing, "rear": side == FiringArc.REAR,
			"water": in_water})
	for p in Damage.clusters(total, 5):
		var hl := HitTable.roll(dice, side)
		var steps := Damage.apply(u, hl["loc"], p, hl["rear"], ["fall"])
		emit.call(GameEvent.DAMAGE, {"unit_id": u.id, "source_id": u.id, "source": "fall",
				"amount": p, "loc": hl["loc"], "rear": hl["rear"], "steps": steps,
				"covered": false, "tac": hl["tac"]})
		Damage.announce(emit, u)
		HeadHit.check(dice, emit, u, steps)
		CriticalHits.after_damage(state, dice, emit, u, steps, hl["tac"])
		HullBreach.after_damage(state, dice, emit, u, steps)
	HullBreach.check_exposed(state, emit, u)
	if not u.destroyed:
		seatbelt(dice, emit, u, levels)


static func seatbelt(dice: Dice, emit: Callable, u: Unit, levels: int) -> void:
	var th := ToHit.new()
	th.add("Piloting", u.pilot.piloting, "Your MechWarrior's piloting skill is the base number.")
	if levels > 0:
		th.add("fell %d level%s" % [levels, "" if levels == 1 else "s"], levels, "")
	if ToHitCalc.is_immobile(u) or th.target() > 12:
		PilotDamage.wound(dice, emit, u, 1, "fall")
		return
	var r := dice.roll_2d6()
	var ok := r >= th.target()
	emit.call(GameEvent.PSR, {"unit_id": u.id, "roll": r, "need": th.target(), "ok": ok,
			"reason": "seatbelt check", "mods": th.mods})
	if not ok:
		PilotDamage.wound(dice, emit, u, 1, "fall")
