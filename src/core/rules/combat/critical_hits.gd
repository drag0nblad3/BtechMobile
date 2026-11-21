class_name CriticalHits
extends RefCounted
## Critical hits. Whenever damage reaches internal structure (or a hit
## location roll of 2), roll 2d6: 8-9 one critical, 10-11 two, 12 three
## (a head or limb is blown off instead). Each critical hits a random slot.
## Transfer (book p. 95): a location that started the phase with nothing
## left to hit passes its criticals inward; otherwise extra criticals are
## lost. A location destroyed by the damage still rolls, but only hits on
## explosive slots (ammo) count (p. 87).


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
		if checked.has(loc) or (not st["breached"] and not first_tac) or u.destroyed:
			continue
		checked[loc] = true
		var mod := -1 if st.get("case2", false) else 0  # CASE II (p. 91)
		if st["destroyed"]:
			if _has_explosive(u, loc):
				roll_location(state, dice, emit, u, loc, true, mod)
			continue
		if u.is_location_destroyed(loc):
			continue
		roll_location(state, dice, emit, u, loc, false, mod)


## explosive_only: the location was just destroyed; only ammo hits count.
static func roll_location(state: GameState, dice: Dice, emit: Callable, u: Unit, loc: int,
		explosive_only: bool = false, mod := 0) -> void:
	var roll := dice.roll_2d6() + mod
	var n := crits_for_roll(roll)
	emit.call(GameEvent.CRIT_CHECK, {"unit_id": u.id, "loc": loc, "roll": roll, "crits": n})
	if explosive_only:
		for i in n:
			_explosive_hit(state, dice, emit, u, loc)
		return
	if roll >= 12 and (loc == Location.HEAD or Location.is_arm(loc) or Location.is_leg(loc)):
		Damage.destroy_location(u, loc)
		emit.call(GameEvent.CRITICAL, {"unit_id": u.id, "loc": loc, "slot": "",
				"effect": "%s blown off" % Location.name_for(u.def, loc)})
		_check_destroyed(emit, u)
		return
	for i in n:
		if u.destroyed:
			return
		apply_one(state, dice, emit, u, loc)


## One critical hit in `loc`: a random slot that can still be hit. If the
## location started the phase with nothing to hit, it moves inward
## (unless `transfer` is false: MASC's own criticals never move).
static func apply_one(state: GameState, dice: Dice, emit: Callable, u: Unit, loc: int, transfer := true) -> void:
	var options := _hittable(u, loc)
	while options.is_empty():
		if not transfer or _hit_this_phase(state, u, loc):
			return
		loc = Location.transfer(loc)
		if loc < 0 or u.is_location_destroyed(loc):
			return
		options = _hittable(u, loc)
	hit_slot(state, dice, emit, u, loc, options[dice.pick(options.size())])


## A critical hit on one chosen slot (the supercharger picks engine slots).
static func hit_slot(state: GameState, dice: Dice, emit: Callable, u: Unit, loc: int, slot: CritSlot) -> void:
	slot.hit = true
	slot.hit_when = _now(state)
	var effect := CritEffects.apply(state, dice, emit, u, loc, slot)
	emit.call(GameEvent.CRITICAL, {"unit_id": u.id, "loc": loc, "slot": slot.name, "effect": effect})
	_check_destroyed(emit, u)


## A just-destroyed location: pick a slot as usual; only ammo explodes.
static func _explosive_hit(state: GameState, dice: Dice, emit: Callable, u: Unit, loc: int) -> void:
	var options := _hittable(u, loc)
	if options.is_empty() or u.destroyed:
		return
	var slot := options[dice.pick(options.size())]
	if slot.kind != CritSlot.Kind.AMMO:
		return
	slot.hit = true
	slot.hit_when = _now(state)
	u.ammo[slot.ref].destroyed = false  # the location's loss doesn't empty the bin
	var effect := CritEffects.apply(state, dice, emit, u, loc, slot)
	emit.call(GameEvent.CRITICAL, {"unit_id": u.id, "loc": loc, "slot": slot.name, "effect": effect})
	_check_destroyed(emit, u)


static func _hittable(u: Unit, loc: int) -> Array[CritSlot]:
	var out: Array[CritSlot] = []
	for s: CritSlot in u.slots[loc]:
		if s.can_be_hit() or AutocannonCrit.rehittable(u, s):
			out.append(s)
	return out


static func _has_explosive(u: Unit, loc: int) -> bool:
	for a in u.ammo:
		if a.loc == loc and a.shots > 0:
			return true
	return false


static func _hit_this_phase(state: GameState, u: Unit, loc: int) -> bool:
	for s: CritSlot in u.slots[loc]:
		if s.hit and s.hit_when == _now(state):
			return true
	return false


static func _now(state: GameState) -> int:
	return state.turn * 10 + state.phase


static func _check_destroyed(emit: Callable, u: Unit) -> void:
	Damage.announce(emit, u)
