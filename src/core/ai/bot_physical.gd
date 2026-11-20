class_name BotPhysical
extends RefCounted
## Bot physical attacks: the best of punches (both arms), a kick, or a
## hatchet, sword or club swing, by expected damage. A kick counts the
## chance that a miss knocks the bot over; melee weapons get a small bonus
## when they force the target to make a piloting roll (clubs).

const PSR_BONUS := 1.5  ## Expected-damage value of making the target roll.


## Returns {attacks: [{kind, limb, target_id}], reason, value}.
static func plan(s: GameState, u: Unit) -> Dictionary:
	var best := {"attacks": [], "reason": "", "value": 0.0}
	for e in s.units:
		if e.side == u.side or e.destroyed:
			continue
		var punches := []
		var punch_val := 0.0
		for o in PhysicalOptions.for_target(s, u, e):
			var th: ToHit = o["to_hit"]
			var kind: String = o["kind"]
			if not th.possible() or kind == "push":
				continue
			var v: float = th.chance() * o["damage"]
			if kind == "punch":
				punches.append({"kind": "punch", "limb": o["limb"], "target_id": e.id})
				punch_val += v
				continue
			var why := "%s %s (%s to hit)" % [Explainer.PHYS_VERBS.get(kind, kind), Names.unit(e), Names.pct(th.chance())]
			if kind == "kick":
				var fall_risk := (1.0 - th.chance()) * (1.0 - Dice.chance_2d6(Psr.standing_mods(u).target()))
				v -= fall_risk * Fall.damage_for(u, 0)
			elif kind == "club":
				v += th.chance() * PSR_BONUS
				why += ", and the target must roll to stay standing"
			if v > best["value"]:
				best = {"attacks": [{"kind": kind, "limb": o["limb"], "target_id": e.id}],
						"value": v, "reason": why}
		if punch_val > best["value"]:
			best = {"attacks": punches, "value": punch_val,
					"reason": "punches %s (%.1f expected)" % [Names.unit(e), punch_val]}
	return best
