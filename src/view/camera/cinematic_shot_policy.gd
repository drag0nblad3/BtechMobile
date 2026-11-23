class_name CinematicShotPolicy
extends RefCounted
## Selects only legible, consequential visual moments; never changes rules.


static func weapon_kind(d: Dictionary) -> String:
	if not bool(d.get("hit", false)) or bool(d.get("no_ammo", false)) \
			or bool(d.get("streak_held", false)):
		return ""
	var weapon := String(d.get("weapon_id", d.get("weapon_name", ""))).to_lower()
	if weapon == "":
		return "pair"  # Older event records lack a weapon identifier.
	var family := ShotFx.style(weapon)
	if family == "missile":
		return "missile"
	if family == "ppc" or "gauss" in weapon or "ac_20" in weapon or "ac20" in weapon:
		return "pair"
	return ""


static func follow_move(d: Dictionary) -> bool:
	if int(d.get("mode", -1)) == MoveMode.Kind.JUMP:
		return true
	var hexes: Variant = d.get("hexes", 0)
	return (typeof(hexes) == TYPE_INT or typeof(hexes) == TYPE_FLOAT) and int(hexes) >= 5
