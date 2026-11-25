class_name BotPhysical
extends RefCounted
## Bot physical attacks: the best of punches (both arms), a kick, or a
## hatchet, sword or club swing, by expected damage. A kick counts the
## chance that a miss knocks the bot over; melee weapons get a small bonus
## when they force the target to make a piloting roll (clubs). A push is
## worth the chance the shove knocks the target down, more if it shoves it
## off a ledge, and far more if it shoves it off the map.

const PSR_BONUS := 1.5  ## Expected-damage value of making the target roll.
const CLUB_IF_FIRE_BELOW := 2.0  ## Expected weapon damage under which a club is better.
const CLUB_RANGE := 3
const BRUSH_BONUS := 10.0  ## Getting a swarming squad off is worth a lot.
const OFF_MAP_VALUE := 100.0  ## Shoving a 'Mech off the battlefield destroys it.


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
			if not th.possible():
				continue
			var v: float = th.chance() * o["damage"]
			if kind == "punch":
				punches.append({"kind": "punch", "limb": o["limb"], "target_id": e.id})
				punch_val += v
				continue
			var why := "%s %s (%s to hit)" % [Explainer.PHYS_VERBS.get(kind, kind), Names.unit(e), Names.pct(th.chance())]
			if kind == "push":
				v = th.chance() * push_value(s, u, e)
				why += ": %s" % _push_note(s, u, e)
			elif kind == "kick" or kind == Zweihander.KIND:
				var fall_risk := (1.0 - th.chance()) * (1.0 - Dice.chance_2d6(Psr.standing_mods(u).target()))
				v -= fall_risk * Fall.damage_for(u, 0)
			elif kind == "brush_off":
				v += th.chance() * BRUSH_BONUS
				why += ", knocking the swarming troopers off"
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


## Expected value of a successful push on `e`: its fall chance times fall
## damage, a ledge's extra levels, or the whole 'Mech if off the map.
static func push_value(s: GameState, u: Unit, e: Unit) -> float:
	var to := Hex.neighbor(e.coord, Hex.direction_to(u.coord, e.coord))
	var dst := s.map.get_tile(to)
	if dst == null:
		return OFF_MAP_VALUE
	var drop := Roofs.floor_of(s.map, e) - dst.floor_level()
	var fall := 1.0 - Dice.chance_2d6(Psr.standing_mods(e).target())
	var v := fall * Fall.damage_for(e, 0)
	if drop >= 2:
		v = maxf(v, Fall.damage_for(e, drop))
	return v


static func _push_note(s: GameState, u: Unit, e: Unit) -> String:
	var to := Hex.neighbor(e.coord, Hex.direction_to(u.coord, e.coord))
	if s.map.get_tile(to) == null:
		return "shoving it off the battlefield destroys it"
	return "the shove may knock it down"


## Picks up a tree or girder instead of firing when its guns would do
## little and an enemy is close enough to club next turn. Returns the
## reason, or "" to fire as usual.
static func club_instead(s: GameState, u: Unit, fire_value: float) -> String:
	var club := MeleeWeapons.club_here(s, u)
	if club == "" or fire_value >= CLUB_IF_FIRE_BELOW:
		return ""
	var e := BotMove.nearest_enemy(s, u, u.coord)
	if e == null or Hex.distance(u.coord, e.coord) > CLUB_RANGE:
		return ""
	return "picks up a %s to club %s (its weapons would do only %.1f)" % [club, Names.unit(e), fire_value]
