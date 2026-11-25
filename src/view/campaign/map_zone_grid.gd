class_name MapZoneGrid
extends Control
## Scalable hex cartography. The canvas owns hit testing, not rectangular buttons.

const COLORS := {"plains": Color("#667d50"), "woods": Color("#315946"), "hills": Color("#827b59"), "badlands": Color("#9b704b"), "lakes": Color("#345e78"), "river": Color("#526d59"), "urban": Color("#68717c")}
const BLUE := Color("#7cdaf5")
const RED := Color("#f29282")
const GOLD := Color("#ffd483")
var mc: MapCampaign
var chosen: MapLance
var pending := ""
var overlay := 0
var selected := Vector2i(-1, -1)
var zoom := 1.0
var pan := Vector2.ZERO
var _tap: Callable
var _dragging := false
var _origin := Vector2.ZERO
var _last := Vector2.ZERO
var _seen := {}
var _route: Array[Vector2i] = []
var _moves: Array[Dictionary] = []
var _captures: Array[Vector2i] = []
var _animation := 1.0


static func make(parent: Control, campaign: MapCampaign, on_tap: Callable, lance: MapLance, order := "", layer := 0, inspect := Vector2i(-1, -1)) -> MapZoneGrid:
	var g := MapZoneGrid.new()
	g.name = "ZoneGrid"
	g.mc = campaign
	g.chosen = lance
	g.pending = order
	g.overlay = layer
	g.selected = inspect
	g._tap = on_tap
	g._seen = MapFog.seen(campaign)
	if lance != null and lance.on_map():
		if campaign.region.has_zone(lance.target) and (lance.order == MapLance.DROPSHIP or (lance.order == MapLance.MOVE and MapFactory.sea_route(campaign, lance, lance.target))):
			g._route = [lance.zone, lance.target]
		else:
			g._route = MapGeography.route(campaign.region, lance.zone, lance.target)
	g.custom_minimum_size = Vector2(0, 410)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	g.clip_contents = true
	g.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(g)
	return g


func _radius() -> float:
	return maxf(1.0, minf((size.x - 24.0) / (mc.region.width * 1.5 + 0.5), (size.y - 24.0) / ((mc.region.height + 0.5) * sqrt(3.0)))) * zoom


func center(z: Vector2i) -> Vector2:
	var r := _radius()
	var extent := Vector2(mc.region.width * 1.5 + 0.5, (mc.region.height + 0.5) * sqrt(3.0)) * r
	return (size - extent) * 0.5 + pan + Vector2(r * (1.0 + z.x * 1.5), r * sqrt(3.0) * (0.5 + z.y + 0.5 * (z.x % 2)))


func polygon(z: Vector2i, inset := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 6:
		points.append(center(z) + Vector2.from_angle(i * PI / 3.0) * maxf(1.0, _radius() - inset))
	return points


func zone_at(point: Vector2) -> Vector2i:
	for x in mc.region.width:
		for y in mc.region.height:
			var z := Vector2i(x, y)
			if Geometry2D.is_point_in_polygon(point, polygon(z)):
				return z
	return Vector2i(-1, -1)


func set_zoom(value: float) -> void:
	zoom = clampf(value, 1.0, 2.8)
	if zoom == 1.0:
		pan = Vector2.ZERO
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			set_zoom(zoom + 0.25)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			set_zoom(zoom - 0.25)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_origin = event.position
				_last = event.position
			elif _dragging:
				_dragging = false
				if _origin.distance_to(event.position) < 10.0:
					var z := zone_at(event.position)
					if mc.region.has_zone(z):
						_tap.call(z)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		if _origin.distance_to(event.position) >= 10.0 and zoom > 1.0:
			pan += event.position - _last
			pan = pan.clamp(-size * zoom * 0.45, size * zoom * 0.45)
			queue_redraw()
		_last = event.position
		accept_event()


func animate_changes(moves: Array[Dictionary], captures: Array[Vector2i]) -> void:
	if DisplayServer.get_name() == "headless":
		return
	_moves = moves
	_captures = captures
	_animation = 0.0
	var tween := create_tween()
	tween.tween_method(func(v: float): _animation = v; queue_redraw(), 0.0, 1.0, 0.85)
	tween.finished.connect(func(): _moves.clear(); _captures.clear(); queue_redraw())


func _draw() -> void:
	if mc == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#10232d"))
	for x in mc.region.width:
		for y in mc.region.height:
			_tile(Vector2i(x, y))
	# Road network follows neighboring zones; decorative, no movement bonus.
	if not mc.region.locations.is_empty():
		var capital: Vector2i = mc.region.locations[0]["zone"]
		for loc in mc.region.locations:
			var road := MapGeography.route(mc.region, capital, loc["zone"])
			for i in range(1, road.size()):
				draw_line(center(road[i - 1]), center(road[i]), Color("#c7bc8b88"), 1.4, true)
	for i in range(1, _route.size()):
		draw_line(center(_route[i - 1]), center(_route[i]), GOLD, 3.5, true)
		var a := center(_route[i - 1])
		var b := center(_route[i])
		var d := (b - a).normalized()
		draw_colored_polygon(PackedVector2Array([b - d * 10, b - d * 23 + d.orthogonal() * 6, b - d * 23 - d.orthogonal() * 6]), GOLD)
	for x in mc.region.width:
		for y in mc.region.height:
			MapCartography.markers(self, Vector2i(x, y))
	for move in _moves:
		var a := center(move["from"])
		var b := center(move["to"])
		var color := BLUE if int(move["side"]) == 0 else RED
		draw_line(a, b, color, 2.0, true)
		var p := a.lerp(b, _animation)
		draw_circle(p, 9.0, Color("#10232d"))
		draw_arc(p, 9.0, 0, TAU, 24, color, 2.5, true)
	for z in _captures:
		draw_arc(center(z), _radius() * lerpf(0.2, 0.85, _animation), 0, TAU, 32, Color(GOLD, 1.0 - _animation), 3.0, true)


func _tile(z: Vector2i) -> void:
	var p := polygon(z, 0.6)
	var color: Color = COLORS.get(mc.region.terrain_at(z), Color("#56666a"))
	var loc := mc.region.location_at(z)
	if overlay == 1 and not loc.is_empty():
		color = color.lerp(BLUE if int(loc["owner"]) == 0 else RED, 0.55)
	elif overlay == 2 and not _seen.has(z):
		color = color.darkened(0.48)
	elif overlay == 3 and not loc.is_empty() and loc.get("benefit", "") in ["repair", "supply", "factory", "fortress", "dropport", "seaport"]:
		color = color.lerp(GOLD, 0.38)
	draw_colored_polygon(p, color)
	MapCartography.terrain(self, z, color)
	p.append(p[0])
	draw_polyline(p, Color("#172c36"), 1.0, true)
	if chosen != null and pending != "" and MapOrders.why_not(mc, chosen, pending, z) == "":
		draw_polyline(p, BLUE, 2.2, true)
	if z == selected or (chosen != null and z == chosen.zone):
		draw_polyline(p, GOLD, 3.0, true)
