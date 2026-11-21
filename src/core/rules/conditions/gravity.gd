class_name Gravity
extends RefCounted
## Gravity (book p. 121). Away from 1 G, fall damage and building collapse
## damage are multiplied by the G rating (rounded up), and every jump needs
## a piloting roll at -1 for the unfamiliar flight.

const JUMP_MOD := -1


## Damage scaled by gravity, rounded up.
static func scale(damage: int, c: Conditions) -> int:
	if c == null or not c.odd_gravity():
		return damage
	@warning_ignore("integer_division")
	return (damage * c.gravity_tenths() + 9) / 10


## The piloting roll a jump owes in odd gravity, or {} at 1 G.
static func jump_roll(c: Conditions) -> Dictionary:
	if c == null or not c.odd_gravity():
		return {}
	return {"reason": "jumping in %.1f G gravity" % c.gravity, "mod": JUMP_MOD}
