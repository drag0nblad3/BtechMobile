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
			return gc.submit_move(u, m["key"], m["mode"])
		Phase.Kind.WEAPON_ATTACK:
			var f := BotFire.plan(s, u)
			if f["twist"] != 0:
				gc.set_torso_twist(u, f["twist"])
			gc.announce(u, f["reason"] + (" (twists its torso)" if f["twist"] != 0 else ""))
			return gc.declare_fire(u, f["shots"])
		Phase.Kind.PHYSICAL_ATTACK:
			var p := _physical(s, u)
			if not p["attacks"].is_empty():
				gc.announce(u, p["reason"])
			return gc.declare_physical(u, p["attacks"])
	return false


## Best punch(es) or kick by expected damage; avoids kicks when a miss
## would probably knock it over.
static func _physical(s: GameState, u: Unit) -> Dictionary:
	var best := {"attacks": [], "reason": "", "value": 0.0}
	for e in s.units:
		if e.side == u.side or e.destroyed:
			continue
		var punches := []
		var punch_val := 0.0
		for o in PhysicalOptions.for_target(s, u, e):
			var th: ToHit = o["to_hit"]
			if not th.possible() or o["kind"] == "push":
				continue
			var v: float = th.chance() * o["damage"]
			if o["kind"] == "punch":
				punches.append({"kind": "punch", "limb": o["limb"], "target_id": e.id})
				punch_val += v
			else:
				var fall_risk := (1.0 - th.chance()) * (1.0 - Dice.chance_2d6(Psr.standing_mods(u).target()))
				v -= fall_risk * Fall.damage_for(u, 0)
				if v > best["value"]:
					best = {"attacks": [{"kind": "kick", "limb": o["limb"], "target_id": e.id}],
							"value": v, "reason": "kicks %s (%s to hit)" % [Names.unit(e), Names.pct(th.chance())]}
		if punch_val > best["value"]:
			best = {"attacks": punches, "value": punch_val,
					"reason": "punches %s (%.1f expected)" % [Names.unit(e), punch_val]}
	return best
