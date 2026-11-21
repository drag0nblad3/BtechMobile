class_name Supercharger
extends RefCounted
## Supercharger (book p. 204, Escalating Failure p. 180). Engaged before
## moving, with the same climbing numbers as MASC (Masc.AVOID). Success:
## running MP is twice walking MP; with MASC working too, 2.5 times. A
## failure is a critical check whose hits go to the top-most undamaged
## engine slots in the center torso at the end of the move, and the
## supercharger is wrecked either way.
## TODO(rules): construction (1 slot, engine tons / 10 rounded up to the
## half ton) is general knowledge; BV uses MASC's speed rule only.


static func size_tons(def: UnitDef) -> float:
	var eng := XlEngine.tons(DesignWeight.engine_tons(def.tonnage * def.walk_mp), def.is_xl())
	return ceilf(eng / 10.0 * 2.0) / 2.0


static func need(u: Unit) -> int:
	return Masc.AVOID[mini(u.sc_level, Masc.AVOID.size() - 1)]


static func broken(u: Unit) -> bool:
	if u.sc_lost or u.is_location_out(u.def.supercharger_loc):
		return true
	for s: CritSlot in u.slots[u.def.supercharger_loc]:
		if s.kind == CritSlot.Kind.SUPERCHARGER and s.hit:
			return true
	return false


## Why it can't engage now ("" if it can).
static func problem(u: Unit) -> String:
	if u.def.supercharger_loc < 0:
		return "no supercharger"
	if broken(u):
		return "its supercharger is wrecked"
	if u.has_moved:
		return "it has already moved"
	if u.sc_used:
		return "the supercharger is already engaged this turn"
	if u.walk_mp() <= 0:
		return "it can't walk"
	return ""


static func engage(dice: Dice, emit: Callable, u: Unit) -> bool:
	var target := need(u)
	var roll := dice.roll_2d6()
	u.sc_level += 1
	u.sc_used = true
	u.sc_active = roll >= target
	u.sc_failed = not u.sc_active
	if u.sc_failed:
		u.sc_lost = true
	emit.call(GameEvent.MASC, {"unit_id": u.id, "roll": roll, "need": target, "ok": u.sc_active,
			"next": need(u), "system": "supercharger"})
	return u.sc_active


## A failed roll's engine damage, at the end of the 'Mech's movement.
static func apply_failure(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	if not u.sc_failed or u.destroyed:
		return
	u.sc_failed = false
	var roll := dice.roll_2d6()
	var n := 3 if roll >= 12 else CriticalHits.crits_for_roll(roll)
	emit.call(GameEvent.CRIT_CHECK, {"unit_id": u.id, "loc": Location.CT, "roll": roll, "crits": n, "why": "supercharger"})
	for s: CritSlot in u.slots[Location.CT]:
		if n <= 0 or u.destroyed:
			return
		if s.kind == CritSlot.Kind.ENGINE and not s.hit:
			CriticalHits.hit_slot(state, dice, emit, u, Location.CT, s)
			n -= 1


static func new_turn(u: Unit) -> void:
	if not u.sc_used:
		u.sc_level = maxi(0, u.sc_level - 1)
	u.sc_used = false
	u.sc_active = false
	u.sc_failed = false
