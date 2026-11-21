class_name MapPreview
extends Control
## Small top-down picture of a map for the start screen: terrain colours,
## lighter for higher ground, darker for deeper water, buildings as blocks.

var map: BattleMap = null


func show_map(m: BattleMap) -> void:
	map = m
	queue_redraw()


func _draw() -> void:
	if map == null or map.width == 0:
		return
	# Flat-topped hexes: a column steps 1.5 radii, a row sqrt(3) radii.
	var r := minf(size.x / (map.width * 1.5 + 0.5), size.y / ((map.height + 0.5) * HexLayout.SQRT3))
	var origin := Vector2((size.x - r * (map.width * 1.5 + 0.5)) * 0.5 + r,
			(size.y - r * (map.height + 0.5) * HexLayout.SQRT3) * 0.5 + r * HexLayout.SQRT3 * 0.5)
	var corners := PackedVector2Array()
	for k in 6:
		corners.append(Vector2.from_angle(k * PI / 3.0) * r)
	for c: Vector2i in map.coords():
		var t := map.get_tile(c)
		var o := Hex.to_offset(c)
		var centre := origin + Vector2(o.x * 1.5 * r, (o.y + 0.5 * (o.x % 2)) * HexLayout.SQRT3 * r)
		var pts := PackedVector2Array()
		for p in corners:
			pts.append(centre + p)
		draw_colored_polygon(pts, _colour(t))
		if t.building != null:
			draw_rect(Rect2(centre - Vector2(r, r) * 0.55, Vector2(r, r) * 1.1),
					t.building.type.color.lightened(0.08 * t.building.height))


static func _colour(t: MapTile) -> Color:
	if t.is_water():
		return Color("3d6a8a").darkened(0.18 * (t.depth - 1))
	return t.terrain.top_color.lightened(0.09 * t.level)
