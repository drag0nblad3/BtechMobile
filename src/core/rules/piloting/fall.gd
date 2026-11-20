class_name Fall
extends RefCounted
## A 'Mech falls: it ends up prone facing a random way and takes
## ceil(tons / 10) x (levels fallen + 1) damage in 5-point groups.
## The MechWarrior takes a hit unless a piloting roll succeeds.
## TODO(rules): fall direction table and pilot-damage roll are simplified.

## d6 -> facing change and which side hits the ground.
const DIRECTION := [
	[0, FiringArc.FRONT], [1, FiringArc.RIGHT], [2, FiringArc.RIGHT],
	[3, FiringArc.REAR], [4, FiringArc.LEFT], [5, FiringArc.LEFT],
]


static func damage_for(u: Unit, levels: int) -> int:
	return ceili(u.def.tonnage / 10.0) * (levels + 1)


static func fall(state: GameState, dice: Dice, emit: Callable, u: Unit, levels: int,
		reason: String) -> void:
	var dir: Array = DIRECTION[dice.d6() - 1]
	u.facing = Hex.rotate(u.facing, dir[0])
	u.prone = true
	var total := damage_for(u, levels)
	emit.call(GameEvent.FALL, {"unit_id": u.id, "damage": total, "levels": levels,
			"reason": reason, "facing": u.facing})
	for p in Damage.clusters(total, 5):
		var hl := HitTable.roll(dice, dir[1])
		var steps := Damage.apply(u, hl["loc"], p, hl["rear"])
		emit.call(GameEvent.DAMAGE, {"unit_id": u.id, "source_id": u.id, "source": "fall",
				"amount": p, "loc": hl["loc"], "rear": hl["rear"], "steps": steps,
				"covered": false, "tac": hl["tac"]})
		Damage.announce(emit, u)
		CriticalHits.after_damage(state, dice, emit, u, steps, hl["tac"])
	# Fall damage itself doesn't count toward the 20-point piloting roll.
	u.damage_this_phase -= total
	if not u.destroyed and u.pilot.conscious and not Psr.roll(dice, emit, u, "avoid pilot injury", levels):
		PilotDamage.wound(dice, emit, u, 1, "fall")
