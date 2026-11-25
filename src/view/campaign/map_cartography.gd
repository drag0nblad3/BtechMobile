class_name MapCartography
extends RefCounted
## Lightweight deterministic terrain marks and tactical unit counters.


static func land(g: MapZoneGrid, at: Vector2, r: float, terrain: String, z: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([z, terrain])
	var ink := Color("#142d2d66")
	match terrain:
		"woods":
			for i in 8:
				var p := at + Vector2(rng.randf_range(-0.53, 0.53), rng.randf_range(-0.53, 0.53)) * r
				g.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(5, 4), p + Vector2(-5, 4)]), ink)
		"hills", "badlands":
			for i in 3:
				var p := at + Vector2(-0.4 + i * 0.32, 0.18) * r
				g.draw_polyline(PackedVector2Array([p - Vector2(9, 0), p - Vector2(0, 10), p + Vector2(9, 0)]), ink, 2.0, true)
		"river":
			g.draw_line(at - Vector2(0, r * 0.866), at + Vector2(0, r * 0.866), Color("#7fb9c8"), r * 0.18, true)
		"lakes":
			for i in 3:
				var p := at + Vector2(-0.35, (i - 1) * 0.25) * r
				g.draw_line(p, p + Vector2(r * 0.7, 0), Color("#a2d0d477"), 1.5, true)
		"urban":
			for i in 5:
				var p := at + Vector2(rng.randf_range(-0.45, 0.45), rng.randf_range(-0.45, 0.45)) * r
				g.draw_rect(Rect2(p, Vector2(6, 8)), ink)
		_:
			for i in 4:
				var p := at + Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5)) * r
				g.draw_line(p, p + Vector2(6, -3), ink, 1.0, true)


static func markers(g: MapZoneGrid, z: Vector2i) -> void:
	var mc := g.mc
	var at := g.center(z)
	var r := g.radius
	var font := ThemeDB.fallback_font
	var font_size := clampi(roundi(r * 0.28), 11, 18)
	var loc := mc.region.location_at(z)
	if not loc.is_empty():
		var tint := MapZoneArt.BLUE if int(loc["owner"]) == 0 else MapZoneArt.RED
		var p := at - Vector2(0, r * 0.34)
		g.draw_circle(p, r * 0.20, Color("#152634"))
		g.draw_circle(p, r * 0.20, tint, false, 2.0, true)
		var tag := String(loc["kind"]).left(1).to_upper() + str(loc["points"])
		g.draw_string(font, p - Vector2(9, -4), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, tint)
		if g.overlay == 1:
			g.draw_polyline(MapHexButton.polygon(at, r - 1, true), tint, 3.0, true)
		g.draw_string(font, at - Vector2(r * 0.68, -1), short_label(String(loc["name"]), font, r * 1.36, font_size),
			HORIZONTAL_ALIGNMENT_CENTER, r * 1.36, font_size, Color.WHITE)
	var mine := ""
	var foes := 0
	var fit := 0
	var total := 0
	for l in mc.lances:
		if l.zone != z:
			continue
		if l.side == 0:
			mine += l.name.left(1)
			fit += mc.fit_mechs(l).size()
			total += l.mech_ids.size()
		elif g.seen.has(z):
			foes += 1
	if not mine.is_empty():
		var label := "%d/%d" % [fit, total] if g.overlay == 3 else mine
		_counter(g, at + Vector2(-r * 0.33, r * 0.40), label, MapZoneArt.BLUE)
	if foes > 0:
		_counter(g, at + Vector2(r * 0.34, r * 0.40), str(foes), MapZoneArt.RED)
	elif not g.seen.has(z) and g.overlay == 2:
		_counter(g, at + Vector2(r * 0.34, r * 0.40), "?", Color("#d3dbe1"))
	for b in mc.battles:
		if b["zone"] == z:
			g.draw_arc(at, r * 0.67, 0, TAU, 24, MapZoneArt.GOLD, 3, true)
			break


static func _counter(g: MapZoneGrid, at: Vector2, value: String, color: Color) -> void:
	var rect := Rect2(at - Vector2(15, 9), Vector2(30, 18))
	g.draw_rect(rect, Color("#102331"))
	g.draw_rect(rect, color, false, 1.5)
	g.draw_string(ThemeDB.fallback_font, rect.position + Vector2(1, 13), value,
		HORIZONTAL_ALIGNMENT_CENTER, 28, 12, color)


## Prefer a whole place-name word, with an explicit ellipsis when abbreviated.
static func short_label(full: String, font: Font, width: float, font_size := 11) -> String:
	if font.get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
		return full
	var first := full.get_slice(" ", 0)
	if first != full and font.get_string_size(first + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
		return first + "…"
	var short := full
	while not short.is_empty() and font.get_string_size(short + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		short = short.left(-1)
	return short + "…"
