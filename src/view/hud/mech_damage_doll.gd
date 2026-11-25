class_name MechDamageDoll
extends Control
## Schematic armor/structure readout. The live Unit is the only damage authority.

enum Health { INTACT, WORN, LOW, BREACHED, DESTROYED, FLOODED }
const HUES := [Color("#52cba1"), Color("#ecd27c"), Color("#ef9b58"),
	Color("#f16b6b"), Color("#a5adba"), Color("#68b8f5")]
const LABELS := ["Intact", "Worn", "Low", "Exposed / internal", "Destroyed", "Flooded"]
const CANVAS := Vector2(430, 282)
var unit: Unit


func _ready() -> void:
	custom_minimum_size = Vector2(0, CANVAS.y)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## Each facing has its own armor; internal structure is shared by both.
static func values(u: Unit, loc: int, rear: bool = false) -> Dictionary:
	var armor := u.rear_armor[loc] if rear else u.armor[loc]
	var maximum := u.def.rear_armor[loc] if rear else u.def.armor[loc]
	var partial := u.rear_partial[loc] if rear else u.armor_partial[loc]
	var internal := u.structure[loc]
	var full := StructureTable.points(u.def.tonnage, loc, u.def.quad)
	var status := Health.INTACT
	if u.is_location_destroyed(loc):
		status = Health.DESTROYED
	elif u.flooded.get(loc, false):
		status = Health.FLOODED
	elif armor <= 0 or internal < full or u.structure_partial[loc] > 0:
		status = Health.BREACHED
	elif armor * 2 <= maximum:
		status = Health.LOW
	elif armor < maximum or partial > 0:
		status = Health.WORN
	return {"armor": armor, "max_armor": maximum, "structure": internal,
		"max_structure": full, "health": status}


## Rectangles define hit-location silhouettes, not a chassis or a hit table.
static func layout(quad: bool) -> Dictionary:
	if quad:
		return {Location.HEAD: Rect2(129, 24, 66, 57),
			Location.CT: Rect2(129, 86, 66, 77),
			Location.LT: Rect2(60, 86, 64, 77), Location.RT: Rect2(200, 86, 64, 77),
			Location.LA: Rect2(19, 25, 62, 57), Location.RA: Rect2(243, 25, 62, 57),
			Location.LL: Rect2(19, 168, 62, 69), Location.RL: Rect2(243, 168, 62, 69)}
	# Front-facing: the Mech's right is on the viewer's left.
	return {Location.HEAD: Rect2(129, 24, 66, 57),
		Location.CT: Rect2(129, 86, 66, 77),
		Location.RT: Rect2(65, 86, 60, 77), Location.LT: Rect2(199, 86, 60, 77),
		Location.RA: Rect2(2, 92, 59, 94), Location.LA: Rect2(263, 92, 59, 94),
		Location.RL: Rect2(91, 168, 66, 69), Location.LL: Rect2(167, 168, 66, 69)}


func _draw() -> void:
	if unit == null or unit.def.is_support() or size.x <= 0:
		return
	var scale_factor := minf(size.x / CANVAS.x, size.y / CANVAS.y)
	draw_set_transform(Vector2((size.x - CANVAS.x * scale_factor) * 0.5, 0), 0.0,
		Vector2.ONE * scale_factor)
	draw_rect(Rect2(Vector2.ZERO, CANVAS), Color("#091722"))
	_center(Rect2(0, 0, 324, 21), "QUAD • TOP VIEW" if unit.def.quad else "FRONT ARMOR / STRUCTURE", 15, UiSkin.TEXT)
	_center(Rect2(330, 0, 98, 21), "REAR", 15, UiSkin.TEXT)
	var parts := layout(unit.def.quad)
	# A subdued mechanical frame connects the individual armored sections.
	for pair: Array in [[Location.HEAD, Location.CT], [Location.LT, Location.CT],
			[Location.RT, Location.CT], [Location.LA, Location.LT], [Location.RA, Location.RT],
			[Location.LL, Location.LT], [Location.RL, Location.RT]]:
		var a: Rect2 = parts[pair[0]]
		var b: Rect2 = parts[pair[1]]
		draw_line(a.get_center(), b.get_center(), Color("#425464"), 10.0, true)
	for loc: int in parts:
		_section(parts[loc], loc, false)
	for i in Location.HAS_REAR.size():
		var loc: int = [Location.RT, Location.CT, Location.LT][i]
		_section(Rect2(333, 24 + i * 72, 94, 68), loc, true)
	# Words and exact pip counts supplement color for color-vision accessibility.
	for i in Health.size():
		var at := Vector2(6 + (i % 3) * 143, 244 + floori(i / 3.0) * 18)
		draw_rect(Rect2(at, Vector2(11, 11)), HUES[i])
		draw_string(get_theme_default_font(), at + Vector2(16, 11), LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiSkin.TEXT)


func _section(rect: Rect2, loc: int, rear: bool) -> void:
	var data := values(unit, loc, rear)
	var health: int = data["health"]
	var hue: Color = HUES[health]
	var p := rect.position
	var q := rect.end
	var cut := 8.0
	var points := PackedVector2Array([p + Vector2(cut, 0), Vector2(q.x - cut, p.y),
		Vector2(q.x, p.y + cut), q - Vector2(0, cut), q - Vector2(cut, 0),
		Vector2(p.x + cut, q.y), Vector2(p.x, q.y - cut), p + Vector2(0, cut)])
	draw_colored_polygon(points, Color("#12222e").lerp(hue, 0.19 if health == Health.DESTROYED else 0.36))
	points.append(points[0])
	draw_polyline(points, hue, 2.0, true)
	if health == Health.DESTROYED:
		draw_line(p + Vector2(9, 9), q - Vector2(9, 9), Color("#a5adba55"), 3.0, true)
		draw_line(Vector2(p.x + 9, q.y - 9), Vector2(q.x - 9, p.y + 9), Color("#a5adba55"), 3.0, true)
	var middle := rect.get_center().y
	var label := Location.code_for(unit.def, loc)
	if health == Health.DESTROYED:
		label += " ×"
	elif health in [Health.BREACHED, Health.FLOODED]:
		label += " !"
	_center(Rect2(p.x, middle - 25, rect.size.x, 20), label, 16, hue)
	_center(Rect2(p.x, middle - 6, rect.size.x, 18), "A %d/%d" % [data["armor"], data["max_armor"]], 13, UiSkin.TEXT)
	_center(Rect2(p.x, middle + 11, rect.size.x, 18), "S %d/%d" % [data["structure"], data["max_structure"]], 13, UiSkin.TEXT)


func _center(rect: Rect2, value: String, font_size: int, hue: Color) -> void:
	var font := get_theme_default_font()
	var baseline := rect.position.y + (rect.size.y - font.get_height(font_size)) * 0.5 + font.get_ascent(font_size)
	draw_string(font, Vector2(rect.position.x, baseline), value, HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x, font_size, hue)
