class_name WaterCombat
extends RefCounted
## Fighting in water (book pp. 62, 66-67, 77, 127). A 'Mech is underwater
## standing in depth 2+ or prone in depth 1+; standing in depth 1 it wades,
## legs under. Shots can't cross the water line: land and underwater 'Mechs
## can't shoot each other. Only energy weapons fire from a submerged
## location; a wading 'Mech's leg weapons fire only at targets in water, and
## leg shots at a wading target (or any shot from underwater at one) hit the
## legs on the Kick table, ignoring partial cover. Energy weapons firing
## underwater count one range bracket longer, and long range is out.
## Physical attacks can only reach an underwater 'Mech from underwater (or a
## kick from depth 1), and deal half damage to a submerged location.
## Hull breaches: see HullBreach.
## TODO(rules): torpedoes.

enum Zone { DRY, WADING, UNDER }


static func zone(map: BattleMap, u: Unit) -> int:
	var tile := map.get_tile(u.coord)
	if tile == null or not tile.is_water() or u.on_roof or u.on_bridge:
		return Zone.DRY
	if u.def.is_support():
		return Zone.DRY  # only hovercraft enter water, and they ride the surface
	if tile.depth >= 2 or u.prone:
		return Zone.UNDER
	return Zone.WADING


## Is this location of the 'Mech under water?
static func submerged(map: BattleMap, u: Unit, loc: int) -> bool:
	var z := zone(map, u)
	return z == Zone.UNDER or (z == Zone.WADING and Location.is_leg_of(u.def, loc))


## {impossible: String, legs_only: bool, under_range: bool} for a shot.
static func shot(map: BattleMap, a: Unit, w: MountedWeapon, t: Unit) -> Dictionary:
	var out := {"impossible": "", "legs_only": false, "under_range": false}
	var az := zone(map, a)
	var tz := zone(map, t)
	var wet := submerged(map, a, w.loc)
	if wet and w.def.type != "energy":
		out["impossible"] = "Only energy weapons fire under water"
	elif (az == Zone.UNDER and tz == Zone.DRY) or (az == Zone.DRY and tz == Zone.UNDER):
		out["impossible"] = "Shots can't cross the water line"
	elif az == Zone.WADING and wet and tz == Zone.DRY:
		out["impossible"] = "Leg weapons under water can only hit targets in the water"
	elif az == Zone.WADING and not wet and tz == Zone.UNDER:
		out["impossible"] = "Only weapons under water can reach a submerged target"
	elif az == Zone.UNDER and not _wet_line(map, a.coord, t.coord):
		out["impossible"] = "Underwater shots can't pass through dry or shallow hexes"
	if out["impossible"] != "":
		return out
	out["under_range"] = wet
	out["legs_only"] = tz == Zone.WADING and wet
	return out


## Why a physical attack can't reach the target through the water, or "".
static func physical_blocked(map: BattleMap, a: Unit, t: Unit, kind: String) -> String:
	if zone(map, t) != Zone.UNDER or zone(map, a) == Zone.UNDER:
		return ""
	if kind == "kick" and zone(map, a) == Zone.WADING:
		return ""
	return "The target is under water; only a kick from the water can reach it"


## Physical damage after halving for a submerged location.
static func physical_damage(map: BattleMap, t: Unit, loc: int, amount: int) -> int:
	@warning_ignore("integer_division")
	return amount / 2 if submerged(map, t, loc) else amount


static func _wet_line(map: BattleMap, a: Vector2i, b: Vector2i) -> bool:
	var line := Hex.line(a, b)
	for i in range(1, line.size() - 1):
		var tile := map.get_tile(line[i])
		if tile == null or not tile.is_water():
			return false
	return true
