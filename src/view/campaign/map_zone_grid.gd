class_name MapZoneGrid
extends Control
## Zoomable flat-top strategic chart. Each transparent button uses an actual
## hex hit region; the cartography is one draw list, not hundreds of panels.

const COLORS := {"plains": Color("#587553"), "woods": Color("#325847"),
	"hills": Color("#80785b"), "badlands": Color("#96694e"),
	"lakes": Color("#315e79"), "river": Color("#577967"), "urban": Color("#687680")}
var mc: MapCampaign
var chosen: MapLance
var pending_order := ""
var overlay := 0  ## terrain, objectives, intelligence, readiness
var radius := 42.0
var seen := {}
var roads: Array = []
var selected := Vector2i(-1, -1)
var _motion: Array[Dictionary] = []
var _motion_t := 1.0


static func make(parent: Control, campaign: MapCampaign, on_tap: Callable, lance: MapLance,
		order := "", mode := 0, zoom := 1.0, inspected := Vector2i(-1, -1)) -> MapZoneGrid:
	var g := MapZoneGrid.new()
	g.name = "ZoneGrid"
	g.mc = campaign
	g.chosen = lance
	g.pending_order = order
	g.overlay = mode
	g.selected = inspected
	g.radius *= zoom
	g.seen = MapFog.seen(campaign)
	g.roads = MapGeography.roads(campaign.region)
	g.custom_minimum_size = Vector2((campaign.region.width * 1.5 + 0.5) * g.radius + 12,
		(campaign.region.height + 0.5) * sqrt(3.0) * g.radius + 12)
	parent.add_child(g)
	for x in campaign.region.width:
		for y in campaign.region.height:
			var z := Vector2i(x, y)
			var b := MapHexButton.new()
			b.name = "Zone_%d_%d" % [x, y]
			b.radius = g.radius
			b.position = g.center(z) - Vector2(g.radius, g.radius * sqrt(3.0) / 2.0)
			b.size = Vector2(g.radius * 2.0, g.radius * sqrt(3.0))
			b.tooltip_text = text_of(campaign, z)
			b.pressed.connect(on_tap.bind(z))
			g.add_child(b)
	return g


func center(z: Vector2i) -> Vector2:
	return Vector2(6 + radius * (1 + z.x * 1.5),
		6 + sqrt(3.0) * radius * (0.5 + z.y + 0.5 * (z.x % 2)))


func _draw() -> void:
	if mc == null:
		return
	for x in mc.region.width:
		for y in mc.region.height:
			var z := Vector2i(x, y)
			var at := center(z)
			var poly := MapHexButton.polygon(at, radius)
			var terrain := mc.region.terrain_at(z)
			var color: Color = COLORS.get(terrain, Color("#53656a"))
			if overlay == 2 and not seen.has(z):
				color = color.darkened(0.45)
			elif overlay == 4:
				var loc := mc.region.location_at(z)
				if not loc.is_empty() and loc.get("benefit", "") in ["repair", "fortress", "supply", "factory", "dropport", "seaport"]:
					color = color.lerp(MapZoneArt.GOLD, 0.45)
				else:
					color = color.darkened(0.35)
			draw_colored_polygon(poly, color)
			draw_polyline(MapHexButton.polygon(at, radius, true), color.darkened(0.4), 1.0, true)
			MapCartography.land(self, at, radius, terrain, z)
			if chosen != null and not pending_order.is_empty() and MapOrders.why_not(mc, chosen, pending_order, z) == "":
				draw_polyline(MapHexButton.polygon(at, radius - 2, true), Color("#e4cc83"), 2.0, true)
	if overlay != 2:
		for route in roads:
			_route(route, Color("#d8b78588"), 1.5)
	for x in mc.region.width:
		for y in mc.region.height:
			var z := Vector2i(x, y)
			MapCartography.markers(self, z)
	if chosen != null and chosen.on_map() and mc.region.has_zone(chosen.target) and chosen.target != chosen.zone:
		var route := MapGeography.route(mc.region, chosen.zone, chosen.target)
		if chosen.order == MapLance.DROPSHIP or MapFactory.sea_route(mc, chosen, chosen.target):
			route.assign([chosen.zone, chosen.target])
		_route(route, Color("#ffe298"), 3.5)
		draw_circle(center(chosen.target), radius * 0.19, Color("#ffe298"), false, 2.0, true)
	for move in _motion:
		var from := center(move["from"])
		var to := center(move["to"])
		var tint := MapZoneArt.BLUE if int(move["side"]) == 0 else MapZoneArt.RED
		var at := from.lerp(to, _motion_t)
		draw_circle(at, radius * (0.18 + 0.25 * _motion_t), Color(tint, 1.0 - _motion_t), false, 3.0, true)
	if mc.region.has_zone(selected):
		draw_polyline(MapHexButton.polygon(center(selected), radius - 2, true), Color.WHITE, 2.5, true)
	if chosen != null and chosen.on_map():
		draw_polyline(MapHexButton.polygon(center(chosen.zone), radius - 4, true), MapZoneArt.BLUE, 3.0, true)


func animate_transitions(transitions: Array[Dictionary]) -> void:
	if transitions.is_empty():
		return
	_motion.assign(transitions)
	_motion_t = 0.0
	var tween := create_tween()
	tween.tween_method(func(t: float): _motion_t = t; queue_redraw(), 0.0, 1.0, 0.65)
	tween.finished.connect(func(): _motion.clear(); queue_redraw())


func _route(route: Array, color: Color, width: float) -> void:
	if route.size() < 2:
		return
	var points := PackedVector2Array()
	for z: Vector2i in route:
		points.append(center(z))
	draw_polyline(points, color, width, true)
	if width > 2.0:
		var tip := points[-1]
		var dir := (tip - points[-2]).normalized()
		draw_colored_polygon(PackedVector2Array([tip, tip - dir * 11 + dir.orthogonal() * 5,
			tip - dir * 11 - dir.orthogonal() * 5]), color)


static func text_of(campaign: MapCampaign, z: Vector2i, _compact := false) -> String:
	var lines := [campaign.region.terrain_at(z).capitalize(), MapLancePanel.where(campaign, z)]
	var loc := campaign.region.location_at(z)
	if not loc.is_empty():
		lines.append("%d points · %s" % [loc["points"], String(loc.get("benefit", "")).capitalize()])
	var visible := MapFog.seen(campaign)
	for l in campaign.lances:
		if l.zone == z and MapFog.shows(campaign, l, visible):
			lines.append(l.name + " · %d/%d fit" % [campaign.fit_mechs(l).size(), l.mech_ids.size()])
	if not visible.has(z):
		lines.append("Enemy presence unknown")
	return "\n".join(lines)
