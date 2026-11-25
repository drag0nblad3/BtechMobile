class_name AttackSockets
extends RefCounted
## Per-mount emitter lookup, with legacy location-only art fallback.
static func index_for(u: Unit, d: Dictionary) -> int:
	var i := int(d.get("weapon_index", -1))
	if i >= 0 and i < u.weapons.size():
		return i
	for n in u.weapons.size():
		if u.weapons[n].def.id == d.get("weapon_id"):
			return n
	return -1


## Distinct mounts share ports by their authored order; missile racks use a
## contiguous subset. Prefer explicit per-index Marker3Ds when available.
static func port_indices(port_count: int, mount_count: int, ordinal: int, missile: bool) -> Array[int]:
	var out: Array[int] = []
	if port_count <= 0:
		return out
	var first := mini(port_count - 1, floori(float(ordinal * port_count) / maxi(1, mount_count)))
	var last := maxi(first + 1, floori(float((ordinal + 1) * port_count) / maxi(1, mount_count)))
	for i in range(first, mini(port_count, last) if missile else first + 1):
		out.append(i)
	return out


static func origins(view: UnitView, d: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var u := view.unit
	var i := index_for(u, d)
	var weapon := String(d.get("weapon_id", ""))
	if i < 0:
		out.append(view.weapon_origin(weapon, i))
		return out
	var w := u.weapons[i]
	var marker := view._find_socket(view._model, "muzzle_%d" % i)
	if marker != null:
		out.append(marker.global_position)
		return out
	if u.def.vehicle != null:
		var bounds := view._model_bounds(view._model, Transform3D.IDENTITY)
		var pos := bounds.get_center()
		match w.loc:
			VehicleLoc.FRONT: pos.z = bounds.position.z
			VehicleLoc.REAR: pos.z = bounds.end.z
			VehicleLoc.LEFT: pos.x = bounds.position.x
			VehicleLoc.RIGHT: pos.x = bounds.end.x
			VehicleLoc.TURRET:
				pos.y = bounds.position.y + bounds.size.y * 0.8
				pos.z = bounds.position.z
		out.append(view.to_global(pos))
		return out
	if view._model is VxMech:
		var m := view._model as VxMech
		if not m.model.parts_at(w.loc).is_empty() and m.is_attached(m.part_at(w.loc)):
			var grid: Array = m.model.muzzles.get(w.loc, [])
			var ports: Array[Vector3] = []
			# Classify authored points in their rest grid, not the rotated rig.
			for p: Vector3 in grid:
				if (p.z > 0.0) == w.rear:
					ports.append(m.part_at(w.loc).to_global(m.part_at(w.loc).local_of(p)))
			if ports.is_empty():
				var part := m.part_at(w.loc)
				var bounds := part.get_aabb()
				var face := bounds.get_center()
				face.z = bounds.end.z if w.rear else bounds.position.z
				out.append(part.to_global(face))
				return out
			var ordinal := 0
			var count := 0
			for n in u.weapons.size():
				if u.weapons[n].loc == w.loc and u.weapons[n].rear == w.rear:
					count += 1
					if n < i:
						ordinal += 1
			for p in port_indices(ports.size(), count, ordinal, w.def.type == "missile"):
				out.append(ports[p])
	if out.is_empty():
		out.append(view.weapon_origin(weapon, i))
	return out
