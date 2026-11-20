class_name HexPicker
extends RefCounted
## Screen point -> hex without physics: intersect the camera ray with each
## level's plane from the top down and keep the first hex whose surface
## is actually at that level.


static func pick(camera: Camera3D, screen_pos: Vector2, map: BattleMap) -> Vector2i:
	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 1e-4:
		return Hex.INVALID
	var range_ := map.level_range()
	for lvl in range(range_.y, range_.x - 1, -1):
		var t_hit := (HexLayout.level_y(lvl) - origin.y) / dir.y
		if t_hit < 0.0:
			continue
		var c := HexLayout.from_world(origin + dir * t_hit)
		var tile := map.get_tile(c)
		if tile and tile.level == lvl:
			return c
	return Hex.INVALID
