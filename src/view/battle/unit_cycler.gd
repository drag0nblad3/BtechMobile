class_name UnitCycler
extends RefCounted
## Picks which of the player's units the camera and the "Next" button go to:
## the units still to act this phase, else every unit of the human side.


## The unit after `current` in the list (wraps), or the first one.
static func after(units: Array[Unit], current: Unit) -> Unit:
	if units.is_empty():
		return null
	var i := units.find(current)
	return units[(i + 1) % units.size()]


## Units the Next button cycles through. Pending ones on the human's turn,
## otherwise all living units of the sides the computer does not play.
static func candidates(controller: GameController, bot_sides: Array) -> Array[Unit]:
	var s := controller.state
	var out: Array[Unit] = []
	if not bot_sides.has(controller.deciding_side()):
		out = controller.pending_units()
	if out.is_empty():
		for u in s.units:
			if not bot_sides.has(u.side) and not u.destroyed and not s.hidden.has(u):
				out.append(u)
	return out
