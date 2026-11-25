class_name AttackVisualGeometry
extends RefCounted
## Event-time visual snapshots and world-space contact positions.
static func pose(state: GameState, d: Dictionary) -> Dictionary:
	var u := state.unit_by_id(int(d.get("attacker_id", -1)))
	return {} if u == null else {"twist": u.torso_twist, "flip": u.arms_flipped}


static func apply_pose(v: UnitView, p: Dictionary) -> void:
	if not v._model is VxMech or p.is_empty():
		return
	var m := v._model as VxMech
	m.anim.declared_twist = -float(p["twist"]) * PI / 3.0
	m.anim.declared_flip = bool(p["flip"])
	var ct := m.model.parts_at(Location.CT)
	if not ct.is_empty():
		var joint: Node3D = m.pivots[ct[0]["name"]]
		joint.rotation.y = m.anim.declared_twist
	for side in 2:
		var sh := m.shoulders[side]
		if m.is_attached(sh):
			sh.rotation.x = PI if m.anim.declared_flip else float(m.model.ready_arm.get("LA" if side == 0 else "RA", 0.0))


static func capture(state: GameState, units: UnitsLayer, e: GameEvent) -> Dictionary:
	var d := e.data
	var v: UnitView = units.views.get(int(d.get("unit_id", -1)))
	var record := {}
	var points: Array[Vector3] = []
	if v != null:
		var u := v.unit
		record = {"armor": u.armor.duplicate(), "rear": u.rear_armor.duplicate(), "structure": u.structure.duplicate(), "destroyed": u.destroyed}
	if e.type == GameEvent.BUILDING:
		var point := hex_point(state, d.get("coord", Hex.INVALID), Vector3.INF)
		if point != Vector3.INF:
			points.append(point)
	elif e.type == GameEvent.DAMAGE and v != null and v.visible:
		var steps: Array = d.get("steps", [])
		if steps.is_empty():
			steps = [d]
		for step: Dictionary in steps:
			var loc := int(step.get("loc", d.get("loc", -1)))
			var rear := bool(step.get("rear", d.get("rear", false)))
			var point := Vector3.INF
			if d.get("covered", false):
				var attacker := state.unit_by_id(int(d.get("source_id", -1)))
				var cover := v.unit.coord
				if attacker != null and d.get("hill", false):
					var traced: Dictionary = LineOfSight.check(state.map, attacker, v.unit)
					var actual: Vector2i = traced.get("cover", Hex.INVALID)
					if actual != Hex.INVALID:
						cover = actual
				point = hex_point(state, cover, HexLayout.to_world(attacker.coord) if attacker != null else Vector3.INF)
			elif v._model is VxMech:
				point = (v._model as VxMech).damage.crater_point(v.unit, step)
			if point == Vector3.INF:
				point = v.impact_location(loc, rear) if loc >= 0 and loc < Location.COUNT else v.global_position + Vector3.UP * 0.4
			points.append(point)
	return {"event": e, "record": record, "points": points}


static func hex_point(state: GameState, coord: Vector2i, from: Vector3) -> Vector3:
	var tile := state.map.get_tile(coord)
	if tile == null:
		return Vector3.INF
	var at := HexLayout.tile_top(tile)
	if tile.building != null:
		at.y += tile.building.height * HexLayout.LEVEL_HEIGHT * 0.5
	elif tile.bridge != null:
		at.y = HexLayout.level_y(tile.bridge.level)
	else:
		at.y += 0.15
	if from != Vector3.INF:
		var dir := (from - at).normalized()
		at += Vector3(dir.x, 0, dir.z) * 0.35
	return at
