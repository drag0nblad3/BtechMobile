class_name Psr
extends RefCounted
## Piloting skill rolls: 2d6 >= piloting skill + modifiers, or the 'Mech falls.
## Owed rolls collect in Unit.psr_pending and are rolled at the end of each phase.
## TODO(rules): verify modifier values and which events need a roll.

const BIG_DAMAGE := 20


## Lasting modifiers from damage, each with a reason.
static func standing_mods(u: Unit) -> ToHit:
	var th := ToHit.new()
	th.add("Piloting", u.pilot.piloting, "Your MechWarrior's piloting skill is the base number.")
	if u.gyro_hits > 0:
		th.add("gyro hit", 3 * u.gyro_hits, "A damaged gyro makes balance hard: +3.")
	if u.legs_destroyed() > 0:
		th.add("leg destroyed", 5 * u.legs_destroyed(), "Balancing on one leg: +5.")
	if u.hip_hits() > 0:
		th.add("hip hit", 2 * u.hip_hits(), "A broken hip: +2.")
	var other := u.leg_actuator_hits() - u.hip_hits()
	if other > 0:
		th.add("leg actuators", other, "Each damaged leg actuator: +1.")
	return th


static func end_of_phase(state: GameState, dice: Dice, emit: Callable) -> void:
	for u in state.units:
		if u.damage_this_phase >= BIG_DAMAGE:
			u.psr_pending.append({"reason": "took %d damage this phase" % u.damage_this_phase, "mod": 1})
		u.damage_this_phase = 0
		if not u.destroyed:
			resolve_pending(state, dice, emit, u)
		u.psr_pending.clear()


static func resolve_pending(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	for p: Dictionary in u.psr_pending:
		if u.prone or u.destroyed:
			return
		if p.get("auto_fall", false) or u.shutdown or not u.pilot.conscious:
			Fall.fall(state, dice, emit, u, 0, p["reason"])
			continue
		if not roll(dice, emit, u, p["reason"], int(p["mod"])):
			Fall.fall(state, dice, emit, u, 0, p["reason"])


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


## A shut-down 'Mech collapses where it stands.
static func fall_from_shutdown(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	if not u.prone:
		Fall.fall(state, dice, emit, u, 0, "shut down")


## Standing up costs 2 MP (already in the move budget) and a piloting roll.
## A destroyed gyro or two missing legs make it impossible.
static func can_stand(u: Unit) -> bool:
	return u.gyro_hits < CritEffects.GYRO_KILL and u.legs_destroyed() < 2


static func try_stand(state: GameState, dice: Dice, emit: Callable, u: Unit) -> bool:
	var ok := can_stand(u) and roll(dice, emit, u, "standing up", 0)
	emit.call(GameEvent.STAND, {"unit_id": u.id, "ok": ok})
	if ok:
		u.prone = false
	else:
		Fall.fall(state, dice, emit, u, 0, "failed to stand")
	return ok
