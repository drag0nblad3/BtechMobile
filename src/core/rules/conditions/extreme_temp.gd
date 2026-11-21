class_name ExtremeTemp
extends RefCounted
## Extreme Temperatures (book p. 120). Each level of Extreme Cold lets a
## 'Mech shed 2 more heat a turn and lowers the Avoid Numbers for heat
## shutdowns and ammo explosions by 1; each level of Extreme Heat adds 2 heat
## a turn and raises them by 1. An Avoid Number pushed to 2 or less passes
## by itself; one pushed past 12 fails by itself.
## Life support: in the cold, a damaged life support system no longer hurts
## the warrior through heat. Instead each cold level costs one hit a Heat
## Phase, minus one hit at 5-10 heat, two at 11-20, three at 21+ (the
## cockpit's own heat keeps the warrior warm). In extreme heat, each level
## adds one hit whenever heat already deals life support hits.
## Water freezing (cold) or drying into sinkholes (heat): Surfaces.

const HEAT_PER_LEVEL := 2


static func heat_added(c: Conditions) -> int:
	return HEAT_PER_LEVEL * c.heat


static func extra_sinks(c: Conditions) -> int:
	return HEAT_PER_LEVEL * c.cold


## Avoid number after temperature: 0 = no roll or automatic pass, 99 = automatic failure.
static func avoid(need: int, c: Conditions) -> int:
	if need == 0 or need >= 99:
		return need
	var n := need + c.heat - c.cold
	if n <= 2:
		return 0
	if n > 12:
		return 99
	return n


## MechWarrior hits from a damaged life support system this Heat Phase,
## given the heat after dissipation.
static func life_support_hits(c: Conditions, heat: int) -> int:
	if c.cold > 0:
		var warm := 0
		if heat >= 21:
			warm = 3
		elif heat >= 11:
			warm = 2
		elif heat >= 5:
			warm = 1
		return maxi(0, c.cold - warm)
	var base := 0
	if heat >= 20:
		base = 2
	elif heat >= 10:
		base = 1
	return base + c.heat if base > 0 else 0
