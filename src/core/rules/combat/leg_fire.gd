class_name LegFire
extends RefCounted
## Leg-mounted weapons can't fire through a hex that gives the firing 'Mech
## partial cover (book p. 61): a hill or building one level up, next to the
## shooter on the line to the target. Water has its own rules (WaterCombat).


## Why a leg weapon can't fire at `target` ("" if it can).
static func blocked(state: GameState, attacker: Unit, w: MountedWeapon, target: Unit) -> String:
	if not Location.is_leg_of(attacker.def, w.loc):
		return ""
	var cover: Vector2i = LineOfSight.check(state.map, target, attacker)["cover"]
	if cover == Hex.INVALID:
		return ""
	return "%s is behind %s, which covers your legs; leg weapons can't fire through it" % [
			w.label(), Hex.label(cover)]
