class_name LowVisibility
extends RefCounted
## Low Visibility (book p. 121): fog banks, blizzards, sandstorms. All ranged
## attacks get +1, line of sight is unchanged. At the start of the Ranged
## Attack Phase each 'Mech makes a sensor check (p. 113: piloting skill, only
## the +2 for a sensor hit applies; two sensor hits make it impossible);
## success ignores the +1 for that turn. Failing never causes a fall.
## TODO(rules): an active probe ignores it for targets in probe range (no probes yet).

const MOD := 1
const SENSOR_HIT_MOD := 2


## Start of the Ranged Attack Phase: every active 'Mech tries to see through.
static func sensor_checks(state: GameState, dice: Dice, emit: Callable) -> void:
	state.sees_through.clear()
	if not state.conditions.low_visibility:
		return
	for u in state.units:
		if u.destroyed or u.shutdown or not u.pilot.conscious:
			continue
		var th := sensor_check_target(u)
		if th.impossible != "":
			continue
		var r := dice.roll_2d6()
		var ok := r >= th.target()
		if ok:
			state.sees_through[u.id] = true
		emit.call(GameEvent.SENSOR_CHECK, {"unit_id": u.id, "roll": r, "need": th.target(), "ok": ok,
				"why": "low visibility", "mods": th.mods})


## A sensor check's target number (p. 113).
static func sensor_check_target(u: Unit) -> ToHit:
	var th := ToHit.new()
	if u.sensor_hits >= 2:
		th.impossible = "sensors destroyed"
		return th
	th.add("Piloting", u.pilot.piloting, "A sensor check uses the piloting skill.")
	if u.sensor_hits == 1:
		th.add("sensor hit", SENSOR_HIT_MOD, "Damaged sensors: +2.")
	return th


## +1 on a ranged attack unless the attacker passed its sensor check this turn.
static func add(th: ToHit, state: GameState, attacker: Unit, target: Unit = null) -> void:
	if not state.conditions.low_visibility or state.sees_through.has(attacker.id):
		return
	if ActiveProbe.clears(state, attacker, target):
		th.add("active probe", 0, "Its active probe sees through the murk at this range: no low visibility penalty.")
		return
	th.add("low visibility", MOD, "Murk covers the battlefield: +1 to every ranged attack. Passing the sensor check at the start of the phase would remove it.")
	EnvSpecialist.add_attack(th, attacker, EnvSpecialist.LOW_VISIBILITY)
