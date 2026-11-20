class_name Bot
extends RefCounted
## A computer opponent. It plays through the same GameController calls as the
## UI, one unit at a time, and announces why it chose each action so a
## learner can compare its thinking with their own.


## Takes the next action for `side` if it is that side's turn. Returns true
## if it acted.
static func act(gc: GameController, side: int) -> bool:
	var s := gc.state
	if s.game_over or s.active_side() != side:
		return false
	var pending := gc.pending_units()
	if pending.is_empty():
		return false
	var u := pending[0]
	match s.phase:
		Phase.Kind.MOVEMENT:
			var m := BotMove.plan(s, u)
			gc.announce(u, m["reason"])
			return gc.submit_move(u, m["key"], m["mode"], m.get("charge", -1))
		Phase.Kind.WEAPON_ATTACK:
			var f := BotFire.plan(s, u)
			if f["twist"] != 0:
				gc.set_torso_twist(u, f["twist"])
			var modes: Dictionary = f.get("modes", {})
			for i: int in modes:
				gc.set_weapon_mode(u, i, modes[i])
			gc.announce(u, f["reason"] + (" (twists its torso)" if f["twist"] != 0 else ""))
			return gc.declare_fire(u, f["shots"])
		Phase.Kind.PHYSICAL_ATTACK:
			var p := BotPhysical.plan(s, u)
			if not p["attacks"].is_empty():
				gc.announce(u, p["reason"])
			return gc.declare_physical(u, p["attacks"])
	return false
