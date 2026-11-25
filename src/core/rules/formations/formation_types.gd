class_name FormationTypes
extends RefCounted
## Formation Types for 'Mech lances (Campaign Operations pp. 60-66): which a
## group of 'Mechs qualifies for. Roles are the official unit roles kept in
## each design's `source.role`. A formation needs 3 or more units; a
## percentage rounds up. If every unit has a type's Ideal Role, its
## requirements are waived (base types only, never variants).
## TODO(rules): faction-only types (Rifle, Hammer, Anvil...), vehicle and
## aerospace types, Light Fire, Anti-Air, Artillery Fire and Support Lances
## aren't offered. "Damage at range N" adds up every weapon that reaches N
## hexes (a missile rack counts all its missiles); "a weapon that does N"
## is one weapon alone.

## Offered types, in the order detection prefers them.
const ORDER := ["light_recon", "heavy_recon", "recon", "light_striker", "heavy_striker", "striker",
		"pursuit", "probe", "sweep", "fire_support", "direct_fire", "fire", "assault", "command",
		"light_battle", "medium_battle", "heavy_battle", "battle", "ranger"]
const NAMES := {"battle": "Battle Lance", "light_battle": "Light Battle Lance", "medium_battle": "Medium Battle Lance",
		"heavy_battle": "Heavy Battle Lance", "assault": "Assault Lance", "fire": "Fire Lance",
		"fire_support": "Fire Support Lance", "direct_fire": "Direct Fire Lance", "striker": "Striker/Cavalry Lance",
		"light_striker": "Light Striker/Cavalry Lance", "heavy_striker": "Heavy Striker/Cavalry Lance",
		"pursuit": "Pursuit Lance", "probe": "Probe Lance", "sweep": "Sweep Lance", "recon": "Recon Lance",
		"light_recon": "Light Recon Lance", "heavy_recon": "Heavy Recon Lance", "command": "Command Lance",
		"ranger": "Ranger Lance"}
const IDEAL := {"assault": "Juggernaut", "battle": "Brawler", "fire": "Missile Boat", "pursuit": "Skirmisher",
		"recon": "Scout", "striker": "Striker", "ranger": "Skirmisher"}
const MIN_UNITS := 3


## Every type `units` qualify for, in ORDER.
static func qualifying(units: Array[Unit]) -> Array[String]:
	var out: Array[String] = []
	for t: String in ORDER:
		if qualifies(t, units):
			out.append(t)
	return out


static func qualifies(t: String, us: Array[Unit]) -> bool:
	if us.size() < MIN_UNITS:
		return false
	if IDEAL.has(t) and _all(us, func(u: Unit) -> bool: return role(u) == IDEAL[t]):
		return true
	match t:
		"battle":
			return _share(us, _heavy) >= 0.5 and _count(us, _roles(["Brawler", "Sniper", "Skirmisher"])) >= 3
		"light_battle":
			return _share(us, _class("Light")) >= 0.75 and _none(us, _class("Assault")) and _count(us, _roles(["Scout"])) >= 1
		"medium_battle":
			return _share(us, _class("Medium")) >= 0.5 and _none(us, _class("Assault"))
		"heavy_battle":
			return _share(us, _heavy) >= 0.5 and _none(us, _class("Light"))
		"assault":
			return _count(us, _heavy) >= 3 and _none(us, _class("Light")) \
					and _all(us, func(u: Unit) -> bool: return u.def.total_armor() >= 135) \
					and _share(us, func(u: Unit) -> bool: return damage_at(u, 7) >= 25) >= 0.75 \
					and (_count(us, _roles(["Juggernaut"])) >= 1 or _count(us, _roles(["Sniper"])) >= 2)
		"fire":
			return _share(us, _roles(["Missile Boat", "Sniper"])) >= 0.75
		"fire_support":
			return _count(us, func(u: Unit) -> bool: return u.weapons.any(func(w: MountedWeapon) -> bool: return w.def.indirect)) >= 3
		"direct_fire":
			return _count(us, _heavy) >= 2 and _all(us, func(u: Unit) -> bool: return damage_at(u, 18) >= 10)
		"striker":
			return _all(us, func(u: Unit) -> bool: return u.def.walk_mp >= 5 or u.def.jump_mp >= 4) \
					and _none(us, _class("Assault")) and _share(us, _roles(["Striker", "Skirmisher"])) >= 0.5
		"light_striker":
			return _all(us, _walk(5)) and _none(us, _heavy) and _count(us, _gun(5, 18)) >= 2 \
					and _count(us, _roles(["Striker", "Skirmisher"])) >= 2
		"heavy_striker":
			return _all(us, _walk(4)) and _count(us, _heavy) >= 3 and _none(us, _class("Light")) \
					and _count(us, _gun(5, 18)) >= 1 and _count(us, _roles(["Striker", "Skirmisher"])) >= 2
		"pursuit":
			return _all(us, _light_or_medium) and _share(us, _walk(6)) >= 0.75 and _count(us, _gun(5, 15)) >= 1
		"probe":
			return _none(us, _class("Assault")) and _share(us, _walk(6)) >= 0.75 and _all(us, _reach(10, 9))
		"sweep":
			return _all(us, _light_or_medium) and _all(us, _walk(5)) and _all(us, _reach(10, 6))
		"recon":
			return _all(us, _walk(5)) and _count(us, _roles(["Scout", "Striker"])) >= 2
		"heavy_recon":
			return _all(us, _walk(4)) and _count(us, _walk(5)) >= 2 and _count(us, _heavy) >= 1 \
					and _count(us, _roles(["Scout"])) >= 2
		"light_recon":
			return _all(us, _class("Light")) and _all(us, _walk(6)) and _all(us, _roles(["Scout"]))
		"command":
			var core := _count(us, _roles(["Sniper", "Missile Boat", "Skirmisher", "Juggernaut"]))
			return core >= ceili(us.size() * 0.5) and _count(us, _roles(["Brawler", "Striker", "Scout"])) >= 1
		"ranger":
			return _none(us, _class("Assault"))
	return false


static func name_of(t: String) -> String:
	return NAMES.get(t, t.capitalize())


static func role(u: Unit) -> String:
	return String(u.def.source.get("role", ""))


## Damage the 'Mech can deal at `hexes` (every weapon that reaches that far).
static func damage_at(u: Unit, hexes: int) -> int:
	var total := 0
	for w in u.weapons:
		if w.def.long_range >= hexes:
			total += w.def.damage * maxi(1, w.def.missiles)
	return total


static func _share(us: Array[Unit], f: Callable) -> float:
	return _count(us, f) / float(us.size())


static func _count(us: Array[Unit], f: Callable) -> int:
	return us.filter(f).size()


static func _all(us: Array[Unit], f: Callable) -> bool:
	return us.all(f)


static func _none(us: Array[Unit], f: Callable) -> bool:
	return not us.any(f)


static func _class(c: String) -> Callable:
	return func(u: Unit) -> bool: return u.def.weight_class() == c


static func _heavy(u: Unit) -> bool:
	return u.def.tonnage >= 60


static func _light_or_medium(u: Unit) -> bool:
	return u.def.tonnage < 60


static func _roles(rs: Array) -> Callable:
	return func(u: Unit) -> bool: return rs.has(role(u))


static func _walk(mp: int) -> Callable:
	return func(u: Unit) -> bool: return u.def.walk_mp >= mp


static func _reach(dmg: int, hexes: int) -> Callable:
	return func(u: Unit) -> bool: return damage_at(u, hexes) >= dmg


static func _gun(dmg: int, hexes: int) -> Callable:
	return func(u: Unit) -> bool: return u.weapons.any(func(w: MountedWeapon) -> bool:
		return w.def.long_range >= hexes and w.def.damage * maxi(1, w.def.missiles) >= dmg)
