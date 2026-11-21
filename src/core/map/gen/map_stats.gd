class_name MapStats
extends RefCounted
## Terrain mix of a map: how many hexes of each kind, for the start
## screen's description, map tuning and tests.

var hexes := 0
var counts := {}  ## Terrain id -> hexes ("water" counts only real water).
var buildings := 0
var deep_water := 0  ## Depth 2 or more.
var raised := 0      ## Dry hexes at level 1 or higher.
var top_level := 0


func _init(m: BattleMap) -> void:
	for t: MapTile in m.tiles.values():
		hexes += 1
		var id := t.terrain.id if not (t.terrain.is_water and t.depth == 0) else "clear"
		counts[id] = int(counts.get(id, 0)) + 1
		if t.building != null:
			buildings += 1
		if t.is_water():
			deep_water += 1 if t.depth >= 2 else 0
		elif t.level > 0:
			raised += 1
		top_level = maxi(top_level, t.level)


func count(id: String) -> int:
	return int(counts.get(id, 0))


## Share 0..1 of the map that is terrain `id`.
func share(id: String) -> float:
	return count(id) / float(maxi(1, hexes))


func woods_share() -> float:
	return share("light_woods") + share("heavy_woods")


func summary() -> String:
	var parts := PackedStringArray()
	parts.append("woods %d%% (heavy %d%%)" % [_pct(woods_share()), _pct(share("heavy_woods"))])
	parts.append("hills %d%% (up to level %d)" % [_pct(raised / float(maxi(1, hexes))), top_level])
	parts.append("water %d%%" % _pct(share("water")))
	if share("rough") > 0.0:
		parts.append("rough %d%%" % _pct(share("rough")))
	if share("pavement") > 0.0:
		parts.append("roads %d%%" % _pct(share("pavement")))
	if buildings > 0:
		parts.append("%d building%s" % [buildings, "" if buildings == 1 else "s"])
	return ", ".join(parts)


static func _pct(f: float) -> int:
	return int(round(f * 100.0))
