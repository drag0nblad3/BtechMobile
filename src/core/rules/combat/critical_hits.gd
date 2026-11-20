class_name CriticalHits
extends RefCounted
## Critical hits. Whenever damage reaches internal structure (or a hit
## location roll of 2), roll 2d6: 8-9 one critical, 10-11 two, 12 three
## (a head or limb is blown off instead). Each critical hits a random slot.
## TODO(rules): verify the determining-criticals table and edge cases.


static func crits_for_roll(roll: int) -> int:
	if roll >= 12:
		return 3
	if roll >= 10:
		return 2
	if roll >= 8:
		return 1
	return 0


static func after_damage(state: GameState, dice: Dice, emit: Callable, u: Unit,
		steps: Array[Dictionary], tac: bool) -> void:
	var checked := {}
	for i in steps.size():
		var st: Dictionary = steps[i]
		var loc: int = st["loc"]
		var first_tac := tac and i == 0
		if checked.has(loc) or (not st["breached"] and not first_tac):
			continue
		if u.is_location_destroyed(loc) or u.destroyed:
			continue
		checked[loc] = true
		roll_location(state, dice, emit, u, loc)


static func roll_location(state: GameState, dice: Dice, emit: Callable, u: Unit, loc: int) -> void:
	var roll := dice.roll_2d6()
	var n := crits_for_roll(roll)
	emit.call(GameEvent.CRIT_CHECK, {"unit_id": u.id, "loc": loc, "roll": roll, "crits": n})
	if roll >= 12 and (loc == Location.HEAD or Location.is_arm(loc) or Location.is_leg(loc)):
		Damage.destroy_location(u, loc)
		emit.call(GameEvent.CRITICAL, {"unit_id": u.id, "loc": loc, "slot": "",
				"effect": "%s blown off" % Location.name_of(loc)})
		_after_loss(dice, u, loc)
		_check_destroyed(emit, u)
		return
	for i in n:
		if u.destroyed:
			return
		apply_one(state, dice, emit, u, loc)


## One critical hit in `loc`: a random slot that can still be hit.
## TODO(rules): with no hittable slot the crit is lost (no transfer).
static func apply_one(state: GameState, dice: Dice, emit: Callable, u: Unit, loc: int) -> void:
	var options: Array[CritSlot] = []
	for s: CritSlot in u.slots[loc]:
		if s.can_be_hit():
			options.append(s)
	if options.is_empty():
		return
	var slot := options[dice.pick(options.size())]
	slot.hit = true
	var effect := CritEffects.apply(state, dice, emit, u, loc, slot)
	emit.call(GameEvent.CRITICAL, {"unit_id": u.id, "loc": loc, "slot": slot.name, "effect": effect})
	_check_destroyed(emit, u)


static func _after_loss(_dice: Dice, u: Unit, loc: int) -> void:
	if Location.is_leg(loc):
		u.psr_pending.append({"reason": "leg blown off", "auto_fall": true, "mod": 0})


static func _check_destroyed(emit: Callable, u: Unit) -> void:
	Damage.announce(emit, u)
