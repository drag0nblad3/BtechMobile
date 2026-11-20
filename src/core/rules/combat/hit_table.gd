class_name HitTable
extends RefCounted
## Hit location tables (2d6 for weapons, 1d6 for punches and kicks).
## Index 0 of the 2d6 tables is a roll of 2. TODO(rules): verify tables.

const FRONT := [Location.CT, Location.RA, Location.RA, Location.RL, Location.RT, Location.CT, Location.LT, Location.LL, Location.LA, Location.LA, Location.HEAD]
const LEFT := [Location.LT, Location.LL, Location.LA, Location.LA, Location.LL, Location.LT, Location.CT, Location.RT, Location.RA, Location.RL, Location.HEAD]
const RIGHT := [Location.RT, Location.RL, Location.RA, Location.RA, Location.RL, Location.RT, Location.CT, Location.LT, Location.LA, Location.LL, Location.HEAD]
const PUNCH_FRONT := [Location.LA, Location.LT, Location.CT, Location.RT, Location.RA, Location.HEAD]
const PUNCH_LEFT := [Location.LT, Location.LT, Location.CT, Location.LA, Location.LA, Location.HEAD]
const PUNCH_RIGHT := [Location.RT, Location.RT, Location.CT, Location.RA, Location.RA, Location.HEAD]


## Returns {loc, rear, tac}. `tac`: a roll of 2 may cause a critical hit
## even if the armor holds ("through-armor critical").
static func roll(dice: Dice, arc_id: int) -> Dictionary:
	var r := dice.roll_2d6()
	var table: Array = FRONT
	if arc_id == FiringArc.LEFT:
		table = LEFT
	elif arc_id == FiringArc.RIGHT:
		table = RIGHT
	return {"loc": table[r - 2], "rear": arc_id == FiringArc.REAR, "tac": r == 2, "roll": r}


static func roll_punch(dice: Dice, arc_id: int) -> Dictionary:
	var r := dice.d6()
	var table: Array = PUNCH_FRONT
	if arc_id == FiringArc.LEFT:
		table = PUNCH_LEFT
	elif arc_id == FiringArc.RIGHT:
		table = PUNCH_RIGHT
	return {"loc": table[r - 1], "rear": arc_id == FiringArc.REAR, "tac": false, "roll": r}


static func roll_kick(dice: Dice, arc_id: int) -> Dictionary:
	var r := dice.d6()
	var loc := Location.RL if r <= 3 else Location.LL
	if arc_id == FiringArc.LEFT:
		loc = Location.LL
	elif arc_id == FiringArc.RIGHT:
		loc = Location.RL
	return {"loc": loc, "rear": false, "tac": false, "roll": r}
