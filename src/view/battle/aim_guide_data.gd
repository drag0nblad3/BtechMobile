class_name AimGuideData
extends RefCounted
## Uses LineOfSight and ToHit results; never duplicates LOS math.

const CLEAR := Color("#5ee5a3")
const COVER := Color("#f7bb60")
const BLOCKED := Color("#ff6969")


static func status(los: Dictionary, options: Array) -> String:
	if los.get("blocked", false):
		return "blocked"
	if int(los.get("woods", 0)) > 0 or los.get("cover", Hex.INVALID) != Hex.INVALID:
		return "cover"
	for option: Dictionary in options:
		var th: ToHit = option.get("to_hit")
		if th == null:
			continue
		if "No line of sight" in th.impossible:
			return "blocked"
		if th.cover_hex != Hex.INVALID:
			return "cover"
		for mod: Dictionary in th.mods:
			var label := String(mod.get("label", ""))
			if label in ["woods in the way", "partial cover", "target in woods"] or 					label.begins_with("target in "):
				return "cover"
	return "clear"


static func color_for(status_name: String) -> Color:
	match status_name:
		"blocked": return BLOCKED
		"cover": return COVER
	return CLEAR


static func modifier_hexes(map: BattleMap, source: Vector2i, destination: Vector2i,
		los: Dictionary, options: Array) -> Dictionary:
	var marked := {}
	var cover: Vector2i = los.get("cover", Hex.INVALID)
	for option: Dictionary in options:
		var th: ToHit = option.get("to_hit")
		if th != null and th.cover_hex != Hex.INVALID:
			cover = th.cover_hex
	if cover != Hex.INVALID:
		marked[cover] = Color(COVER, 0.35)
	var status_name := status(los, options)
	# Intervening obstacle candidates: LOS itself determines whether terrain
	# contributes. No damage/cover or woods modifiers are calculated here.
	for c: Vector2i in Hex.line(source, destination):
		if c == source or c == destination:
			continue
		var tile: MapTile = map.get_tile(c)
		if tile == null:
			continue
		if status_name == "blocked" and String(los.get("reason", "")).contains(Hex.label(c)):
			marked[c] = Color(BLOCKED, 0.37)
		elif int(los.get("woods", 0)) > 0 and (LineOfSight.woods_value(tile) > 0
				or tile.on_fire or Obscurant.cloud(tile) > 0):
			marked[c] = Color(COVER, 0.24)
	return marked
