class_name MapZoneArt
extends Control
## Deterministic cartography; decorative only, with the zone button handling input.

const BLUE := Color("#72d2f2")
const RED := Color("#f28a7b")
const GOLD := Color("#f0be70")
const INK := Color("#0d1c2a")

var terrain := ""
var kind := ""
var objective_owner := -1
var friendly := false
var hostile := false
var meeting := false
var direction := Vector2.ZERO
var destination := false


static func attach(b: Button, mc: MapCampaign, z: Vector2i, chosen: MapLance) -> MapZoneArt:
	var a := MapZoneArt.new()
	a.name = "ZoneArt"
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a.clip_contents = true
	a.position = Vector2(4, 4)
	a.size = Vector2(b.size.x - 8, 27)
	a.terrain = mc.region.terrain_at(z)
	var loc := mc.region.location_at(z)
	a.kind = String(loc.get("kind", ""))
	a.objective_owner = int(loc.get("owner", -1))
	for l in mc.lances:
		if l.zone == z:
			a.friendly = a.friendly or l.side == 0
			a.hostile = a.hostile or l.side == 1
	for battle in mc.battles:
		if battle["zone"] == z:
			a.meeting = true
	if chosen != null and chosen.reach() > 0 and mc.region.has_zone(chosen.target) and chosen.target != chosen.zone:
		a.destination = z == chosen.target
		if z == chosen.zone:
			var delta := Vector2(chosen.target - z)
			delta.y += 0.5 * float(chosen.target.x % 2 - z.x % 2)
			a.direction = (delta * Vector2(132, 96)).normalized()
	b.add_child(a)
	return a


func _draw() -> void:
	var colors := {"plains": Color("#385845"), "woods": Color("#264d42"),
		"hills": Color("#625f45"), "badlands": Color("#79513f"),
		"lakes": Color("#285770"), "river": Color("#3a6057"), "urban": Color("#495866")}
	var ground: Color = colors.get(terrain, Color("#3c5360"))
	draw_rect(Rect2(Vector2.ZERO, size), ground)
	draw_rect(Rect2(0, 22, size.x, 5), ground.darkened(0.25))
	_landscape(ground)
	if not kind.is_empty():
		_objective(Vector2(78, 13))
	if friendly:
		draw_rect(Rect2(94, 3, 11, 9), INK)
		draw_rect(Rect2(94, 3, 11, 9), BLUE, false, 1.5)
		draw_line(Vector2(96, 5), Vector2(103, 10), BLUE, 1.2)
		draw_line(Vector2(103, 5), Vector2(96, 10), BLUE, 1.2)
	if hostile:
		_poly(Vector2(100, 19), [Vector2(0,-6), Vector2(6,0), Vector2(0,6), Vector2(-6,0)], RED)
	if meeting:
		draw_circle(Vector2(115, 13), 8, INK)
		draw_line(Vector2(110, 8), Vector2(120, 18), GOLD, 2)
		draw_line(Vector2(120, 8), Vector2(110, 18), GOLD, 2)
	elif destination:
		draw_arc(Vector2(115, 13), 7, 0, TAU, 24, GOLD, 2, true)
		draw_circle(Vector2(115, 13), 2, GOLD)
	elif direction != Vector2.ZERO:
		var center := Vector2(115, 13)
		var tip := center + direction * 8
		var normal := direction.orthogonal()
		draw_circle(center, 9, INK)
		draw_line(center - direction * 7, tip, GOLD, 2, true)
		_poly(tip, [Vector2.ZERO, -direction * 7 + normal * 4, -direction * 7 - normal * 4], GOLD)


func _landscape(ground: Color) -> void:
	match terrain:
		"woods":
			for i in 5:
				var x := 7.0 + i * 12.0
				var h := 12.0 + (i % 3) * 3.0
				draw_rect(Rect2(x - 1, 19, 2, 5), Color("#b3a37d"))
				_poly(Vector2(x, 22), [Vector2(-7,0), Vector2(0,-h), Vector2(7,0)], ground.lightened(0.32))
		"hills", "badlands":
			_poly(Vector2(0, 23), [Vector2.ZERO, Vector2(17,-18), Vector2(31,-7), Vector2(45,-21), Vector2(66,0)], ground.lightened(0.32))
			draw_line(Vector2(17,5), Vector2(24,19), ground.darkened(0.2), 2)
			draw_line(Vector2(45,2), Vector2(52,19), ground.darkened(0.2), 2)
		"lakes", "river":
			if terrain == "river":
				draw_polyline(PackedVector2Array([Vector2(10,0), Vector2(26,9), Vector2(18,18), Vector2(37,27)]), Color("#6398b0"), 8, true)
			for i in 3:
				draw_line(Vector2(7 + i * 19, 7 + i * 6), Vector2(20 + i * 19, 7 + i * 6), Color("#9ec6ce"), 1.4, true)
		"urban":
			for i in 5:
				var x := 4.0 + i * 12
				var h := 11.0 + (i % 3) * 5
				draw_rect(Rect2(x, 23 - h, 9, h), ground.lightened(0.36))
				draw_rect(Rect2(x + 2, 25 - h, 2, 3), INK)
				draw_rect(Rect2(x + 5, 25 - h, 2, 3), INK)
		_:
			for i in 4:
				draw_line(Vector2(3, 8 + i * 5), Vector2(62, 4 + i * 5), ground.lightened(0.24), 1.2, true)


func _objective(p: Vector2) -> void:
	var tint := BLUE if objective_owner == 0 else RED if objective_owner == 1 else Color.WHITE
	draw_rect(Rect2(p - Vector2(11, 11), Vector2(22, 22)), INK)
	draw_rect(Rect2(p - Vector2(11, 11), Vector2(22, 22)), tint, false, 1.5)
	match kind:
		"capital":
			_poly(p, [Vector2(-7,6), Vector2(-7,-2), Vector2(0,-8), Vector2(7,-2), Vector2(7,6)], tint)
			draw_rect(Rect2(p + Vector2(-2,0), Vector2(4,6)), INK)
		"fortress":
			_poly(p, [Vector2(-8,7), Vector2(-8,-7), Vector2(-4,-7), Vector2(-4,-3), Vector2(4,-3), Vector2(4,-7), Vector2(8,-7), Vector2(8,7)], tint)
		"city":
			draw_rect(Rect2(p + Vector2(-7,-2), Vector2(6,9)), tint)
			draw_rect(Rect2(p + Vector2(1,-7), Vector2(6,14)), tint)
		"depot":
			draw_rect(Rect2(p - Vector2(7,7), Vector2(14,14)), tint, false, 2)
			draw_line(p - Vector2(5,5), p + Vector2(5,5), tint, 2)
			draw_line(p + Vector2(-5,5), p + Vector2(5,-5), tint, 2)
		"bridge":
			draw_line(p + Vector2(-8,-3), p + Vector2(8,-3), tint, 2)
			draw_line(p + Vector2(-8,4), p + Vector2(8,4), tint, 2)
			for x: int in [-5, 0, 5]:
				draw_line(p + Vector2(x,-3), p + Vector2(x,4), tint, 2)
		"dropport":  # a landing pad with a DropShip on it
			draw_arc(p, 8, 0, TAU, 16, tint, 1.5)
			_poly(p, [Vector2(0,-7), Vector2(4,3), Vector2(0,1), Vector2(-4,3)], tint)
		_:
			draw_circle(p, 5, tint)


func _poly(origin: Vector2, points: Array, tint: Color) -> void:
	var vertices := PackedVector2Array()
	for point: Vector2 in points:
		vertices.append(origin + point)
	draw_colored_polygon(vertices, tint)
