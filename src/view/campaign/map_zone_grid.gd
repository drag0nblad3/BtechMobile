class_name MapZoneGrid
extends Control
## The campaign region as a grid of zone buttons in offset-hex rows (odd
## columns shifted down): terrain, key location (blue yours, red the
## defender's) and the lances standing there. Tapping a zone calls `on_tap(zone)`.

const W := 132.0
const H := 92.0
const OWNER_TINT := [Color(0.65, 0.85, 1.0), Color(1.0, 0.7, 0.62)]


static func make(parent: Control, mc: MapCampaign, on_tap: Callable, chosen: MapLance) -> MapZoneGrid:
	var g := MapZoneGrid.new()
	g.name = "ZoneGrid"
	g.custom_minimum_size = Vector2(mc.region.width * W, (mc.region.height + 0.5) * H)
	parent.add_child(g)
	for x in mc.region.width:
		for y in mc.region.height:
			g._zone(mc, Vector2i(x, y), on_tap, chosen)
	return g


func _zone(mc: MapCampaign, z: Vector2i, on_tap: Callable, chosen: MapLance) -> void:
	var b := Button.new()
	b.name = "Zone_%d_%d" % [z.x, z.y]
	b.position = Vector2(z.x * W, z.y * H + (H * 0.5 if z.x % 2 == 1 else 0.0))
	b.size = Vector2(W - 4, H - 4)
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 15)
	b.text = text_of(mc, z)
	b.pressed.connect(func(): on_tap.call(z))
	add_child(b)
	var loc := mc.region.location_at(z)
	var tone := "subtle"
	if chosen != null and z == chosen.zone:
		tone = "selected"
	elif chosen != null and z == chosen.target and chosen.target != chosen.zone:
		tone = "primary"
	elif mc.lances_of(0).any(func(l: MapLance) -> bool: return l.zone == z):
		tone = "secondary"
	UiSkin.button(b, tone)
	if not loc.is_empty() and tone == "subtle":
		b.modulate = OWNER_TINT[int(loc["owner"])]


## Three short lines: terrain, location (with points), lances here.
static func text_of(mc: MapCampaign, z: Vector2i) -> String:
	var lines := [mc.region.terrain_at(z).capitalize()]
	var loc := mc.region.location_at(z)
	if not loc.is_empty():
		lines.append("%s %d" % [String(loc["name"]), int(loc["points"])])
	var mine := []
	var foes := 0
	for l in mc.lances:
		if l.zone == z:
			if l.side == 0:
				mine.append(l.name.left(1))
			else:
				foes += 1
	var units := " ".join(mine)
	if foes > 0:
		units += ("  " if units != "" else "") + "Enemy×%d" % foes
	if units != "":
		lines.append(units)
	return "\n".join(lines)
