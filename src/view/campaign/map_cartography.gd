class_name MapCartography
extends RefCounted
## Small terrain marks and military counters drawn at the current map scale.


static func terrain(g: MapZoneGrid, z: Vector2i, color: Color) -> void:
	var p := g.center(z)
	var r := g._radius()
	var kind := g.mc.region.terrain_at(z)
	var ink := color.lightened(0.23)
	match kind:
		"woods":
			for i in 5:
				var at := p + Vector2((i % 3 - 1) * 0.39, (i / 3 - 0.5) * 0.50) * r
				g.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -0.24) * r, at + Vector2(-0.15, 0.16) * r, at + Vector2(0.15, 0.16) * r]), ink)
		"hills", "badlands":
			for i in 3:
				g.draw_arc(p + Vector2((i - 1) * 0.35, 0.15) * r, r * 0.26, PI, TAU, 12, ink, 1.6, true)
		"river":
			var water := Color("#7cb3ca")
			for n in g.mc.region.neighbors(z):
				if g.mc.region.terrain_at(n) in ["river", "lakes"]:
					g.draw_line(p, p.lerp(g.center(n), 0.5), water, r * 0.19, true)
			g.draw_circle(p, r * 0.095, water)
		"lakes":
			g.draw_circle(p, r * 0.64, Color("#447d96"))
			g.draw_line(p - Vector2(r * 0.36, 0), p + Vector2(r * 0.36, 0), ink, 1.2)
		"urban":
			for i in 5:
				var at := p + Vector2((i % 3 - 1) * 0.35, (i / 3 - 0.5) * 0.45) * r
				g.draw_rect(Rect2(at, Vector2(r * 0.23, r * 0.30)), ink)
		_:
			g.draw_line(p + Vector2(-0.4, 0.25) * r, p + Vector2(0.4, 0.1) * r, ink, 1.4)


static func markers(g: MapZoneGrid, z: Vector2i) -> void:
	var p := g.center(z)
	var r := g._radius()
	var font := ThemeDB.fallback_font
	var loc := g.mc.region.location_at(z)
	if not loc.is_empty():
		var owner := MapZoneGrid.BLUE if int(loc["owner"]) == 0 else MapZoneGrid.RED
		var name := String(loc["name"]).get_slice(" ", 0)
		var title := "%s %d" % [name, int(loc["points"])]
		var n := clampi(int(r * 0.31), 11, 20)
		var text_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, n).x
		g.draw_rect(Rect2(p + Vector2(-r * 0.86, -r * 0.66), Vector2(r * 1.72, n + 5)), Color("#12232de6"))
		g.draw_string(font, p + Vector2(-minf(text_width, r * 1.6) * 0.5, -r * 0.66 + n), title, HORIZONTAL_ALIGNMENT_LEFT, r * 1.6, n, owner)
	var friendly := 0
	var hostile := 0
	var ready := 0
	for l in g.mc.lances:
		if l.zone != z or not l.on_map():
			continue
		if l.side == 0:
			friendly += 1
			ready += g.mc.fit_mechs(l).size()
		elif g._seen.has(z):
			hostile += 1
	if friendly > 0:
		_counter(g, p + Vector2(-r * 0.32, r * 0.18), r, MapZoneGrid.BLUE, str(ready) if g.overlay == 4 else str(friendly))
	if hostile > 0:
		_counter(g, p + Vector2(r * 0.32, r * 0.18), r, MapZoneGrid.RED, str(hostile))
	elif g.overlay == 2 and not g._seen.has(z):
		var old: Dictionary = g.mc.intel.get(MapOperations.key(z), {})
		var label := "?" if old.is_empty() else "~%d" % int(old["lances"])
		g.draw_string(font, p + Vector2(-r * 0.22, r * 0.45), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#bac5c9"))
	for b in g.mc.battles:
		if b["zone"] == z:
			g.draw_circle(p, r * 0.16, MapZoneGrid.GOLD)
			break


static func _counter(g: MapZoneGrid, p: Vector2, r: float, color: Color, text: String) -> void:
	var rect := Rect2(p - Vector2(r * 0.25, r * 0.20), Vector2(r * 0.50, r * 0.40))
	g.draw_rect(rect, Color("#10222d"))
	g.draw_rect(rect, color, false, 2)
	g.draw_string(ThemeDB.fallback_font, p + Vector2(-r * 0.14, r * 0.12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10, int(r * 0.33)), color)
