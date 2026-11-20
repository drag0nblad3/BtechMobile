class_name Psr
extends RefCounted
## Piloting skill rolls: 2d6 >= piloting skill + modifiers, or the 'Mech falls.
## Owed rolls collect in Unit.psr_pending and are rolled at the end of each
## phase (book pp. 110-111). Lasting damage always counts: gyro +2, each hip,
## upper or lower leg actuator +1, a destroyed leg +4 instead of that leg's
## actuators. The positive modifiers of every roll owed in the batch apply to
## all of them, and leg actuator hits force only one roll per leg.

const BIG_DAMAGE := 20


## Lasting modifiers from damage, each with a reason.
static func standing_mods(u: Unit) -> ToHit:
	var th := ToHit.new()
	th.add("Piloting", u.pilot.piloting, "Your MechWarrior's piloting skill is the base number.")
	if u.gyro_hits > 0:
		th.add("gyro hit", 2, "A damaged gyro makes balance hard: +2.")
	if u.legs_destroyed() > 0:
		th.add("leg destroyed", 4 * u.legs_destroyed(), "Balancing on one leg: +4.")
	var act := 0
	for loc in [Location.LL, Location.RL]:
		if not u.is_location_destroyed(loc):
			act += leg_actuator_mod(u, loc)
	if act > 0:
		th.add("leg actuators", act, "Each damaged hip, upper or lower leg actuator: +1.")
	return th


## Hip, upper and lower leg actuators hit in one leg (the foot doesn't count).
static func leg_actuator_mod(u: Unit, loc: int) -> int:
	var n := 0
	for s: CritSlot in u.slots[loc]:
		if s.kind == CritSlot.Kind.ACTUATOR and s.hit and s.name != "foot":
			n += 1
	return n


static func end_of_phase(state: GameState, dice: Dice, emit: Callable) -> void:
	for u in state.units:
		if u.damage_this_phase >= BIG_DAMAGE:
			u.psr_pending.append({"reason": "took %d damage this phase" % u.damage_this_phase, "mod": 1})
		u.damage_this_phase = 0
		if not u.destroyed:
			resolve_pending(state, dice, emit, u)
		u.psr_pending.clear()
	PilotDamage.resolve_owed(state, dice, emit)


static func resolve_pending(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	var batch := _dedupe_legs(u.psr_pending)
	var extra := 0
	for p: Dictionary in batch:
		extra += maxi(0, int(p["mod"]))
	for p: Dictionary in batch:
		if u.prone or u.destroyed:
			return
		if p.get("auto_fall", false) or ToHitCalc.is_immobile(u):
			Fall.fall(state, dice, emit, u, 0, p["reason"])
			return
		var others := extra - maxi(0, int(p["mod"]))
		var mod := int(p["mod"]) + others
		if not roll(dice, emit, u, p["reason"], mod):
			Fall.fall(state, dice, emit, u, 0, p["reason"])
			return


## One roll per leg for actuator hits.
static func _dedupe_legs(pending: Array) -> Array:
	var out := []
	var legs := {}
	for p: Dictionary in pending:
		if p.has("leg"):
			if legs.has(p["leg"]):
				continue
			legs[p["leg"]] = true
		out.append(p)
	return out


## One piloting roll. Returns true on success.
static func roll(dice: Dice, emit: Callable, u: Unit, reason: String, mod: int) -> bool:
	var th := standing_mods(u)
	if mod != 0:
		th.add(reason, mod, "")
	var r := dice.roll_2d6()
	var ok := r >= th.target()
	emit.call(GameEvent.PSR, {"unit_id": u.id, "roll": r, "need": th.target(), "ok": ok,
			"reason": reason, "mods": th.mods})
	return ok


## Standing up costs 2 MP (already in the move budget) and a piloting roll.
## A destroyed gyro or two missing legs make it impossible.
static func can_stand(u: Unit) -> bool:
	return u.gyro_hits < CritEffects.GYRO_KILL and u.legs_destroyed() < 2


static func try_stand(state: GameState, dice: Dice, emit: Callable, u: Unit) -> bool:
	var ok := can_stand(u) and roll(dice, emit, u, "standing up", -1)
	emit.call(GameEvent.STAND, {"unit_id": u.id, "ok": ok})
	if ok:
		u.prone = false
	else:
		Fall.fall(state, dice, emit, u, 0, "failed to stand")
	return ok
