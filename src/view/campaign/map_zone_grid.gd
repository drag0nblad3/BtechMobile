class_name MapZoneGrid
extends Control
## The campaign region as a grid of zone buttons in offset-hex rows (odd
## columns shifted down): terrain, key location (blue yours, red the
## defender's) and the lances standing there. Tapping a zone calls `on_tap(zone)`.

const W := 132.0
const H := 96.0


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
	b.add_theme_font_size_override("font_size", 14)
	b.text = text_of(mc, z, true)
	b.tooltip_text = text_of(mc, z)
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
	for key in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := b.get_theme_stylebox(key) as StyleBoxFlat
		style.content_margin_top = 33
		style.content_margin_bottom = 3
		style.content_margin_left = 5
		style.content_margin_right = 5
		if not loc.is_empty() and tone == "subtle" and key != "focus":
			var owner := int(loc["owner"])
			style.border_color = MapZoneArt.BLUE if owner == 0 else MapZoneArt.RED if owner == 1 else UiSkin.BORDER
	MapZoneArt.attach(b, mc, z, chosen)


## Three short lines: terrain, location (with points), lances here (enemy
## lances only where the player can see: MapFog).
static func text_of(mc: MapCampaign, z: Vector2i, compact: bool = false) -> String:
	var seen := MapFog.seen(mc)
	var lines := [mc.region.terrain_at(z).capitalize()]
	var loc := mc.region.location_at(z)
	if not loc.is_empty():
		var place := String(loc["name"])
		if compact:
			place = place.replace(" Supply Depot", " Depot")
		lines.append("%s %d" % [place, int(loc["points"])])
	var mine := []
	var foes := 0
	for l in mc.lances:
		if l.zone == z:
			if l.side == 0:
				mine.append(l.name.left(1))
			elif MapFog.shows(mc, l, seen):
				foes += 1
	var units := " ".join(mine)
	if foes > 0:
		units += ("  " if units != "" else "") + "Enemy×%d" % foes
	if units == "" and not seen.has(z) and int(mc.region.location_at(z).get("owner", 0)) == 1:
		units = "?"
	if units != "":
		lines.append(units)
	return "\n".join(lines)
