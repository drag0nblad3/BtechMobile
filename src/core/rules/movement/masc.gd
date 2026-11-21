class_name Masc
extends RefCounted
## MASC (book p. 204, Escalating Failure p. 180). Engaged when the 'Mech
## picks its movement mode: roll 2d6 before moving. Success lets it run at
## twice its walking MP this turn. The number to beat climbs each turn in a
## row it's used (3, 5, 7, 10, then 11) and drops one step per turn it rests.
## A failure means a critical check whose hits all land in one random leg
## (front/rear kick table) at the end of the move; a 12 is three hits, and
## they never transfer.

const AVOID := [3, 5, 7, 10, 11]
const LEG_BLOWN_OFF_CRITS := 3


## Tons and critical slots (the same number). Inner Sphere: tonnage / 20,
## Clan: tonnage / 25, rounded to the nearest whole number.
## TODO(rules): construction data, not in the Core Rulebook (it lists "*").
static func size(def: UnitDef) -> int:
	return roundi(def.tonnage / (25.0 if def.clan_part("masc") else 20.0))


## The number the roll must reach if engaged now.
static func need(u: Unit) -> int:
	return AVOID[mini(u.masc_level, AVOID.size() - 1)]


## Why it can't engage MASC now ("" if it can).
static func problem(u: Unit) -> String:
	if u.def.masc_loc < 0:
		return "no MASC"
	if broken(u):
		return "its MASC is destroyed"
	if u.has_moved:
		return "it has already moved"
	if u.masc_used:
		return "MASC is already engaged this turn"
	if u.walk_mp() <= 0:
		return "it can't walk"
	return ""


static func broken(u: Unit) -> bool:
	if u.is_location_out(u.def.masc_loc):
		return true
	for s: CritSlot in u.slots[u.def.masc_loc]:
		if s.kind == CritSlot.Kind.MASC and s.hit:
			return true
	return false


## Rolls to engage. Success: running MP is twice walking MP this turn.
## Failure: leg criticals are owed at the end of the move (apply_failure).
static func engage(dice: Dice, emit: Callable, u: Unit) -> bool:
	var target := need(u)
	var roll := dice.roll_2d6()
	u.masc_level += 1
	u.masc_used = true
	u.masc_active = roll >= target
	u.masc_failed = not u.masc_active
	emit.call(GameEvent.MASC, {"unit_id": u.id, "roll": roll, "need": target, "ok": u.masc_active,
			"next": need(u)})
	return u.masc_active


## A failed roll's damage, at the end of the 'Mech's movement.
static func apply_failure(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	if not u.masc_failed or u.destroyed:
		return
	u.masc_failed = false
	var loc: int = HitTable.roll_kick(dice, FiringArc.FRONT, u.def.quad)["loc"]
	var roll := dice.roll_2d6()
	var n := LEG_BLOWN_OFF_CRITS if roll >= 12 else CriticalHits.crits_for_roll(roll)
	emit.call(GameEvent.CRIT_CHECK, {"unit_id": u.id, "loc": loc, "roll": roll, "crits": n, "why": "MASC"})
	for i in n:
		if u.destroyed:
			return
		CriticalHits.apply_one(state, dice, emit, u, loc, false)


## Start of a new turn: a turn of rest lowers the number by one step.
static func new_turn(u: Unit) -> void:
	if not u.masc_used:
		u.masc_level = maxi(0, u.masc_level - 1)
	u.masc_used = false
	u.masc_active = false
	u.masc_failed = false


## Running MP for Battle Value: MASC's top speed.
## TODO(rules): BV 2 detail; the Core Rulebook's BV section doesn't cover MASC.
static func bv_run_mp(def: UnitDef) -> int:
	var boosts := int(def.masc_loc >= 0) + int(def.supercharger_loc >= 0)
	return [def.run_mp(), def.walk_mp * 2, ceili(def.walk_mp * 2.5)][boosts]
