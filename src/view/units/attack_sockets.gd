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
	if view._model is VxMech:
		var m := view._model as VxMech
		if not m.model.parts_at(w.loc).is_empty() and m.is_attached(m.part_at(w.loc)):
			var ports := m.muzzles(w.loc)
			var front: Array[Vector3] = []
			for p: Vector3 in ports:
				if (m.to_local(p).z > 0.0) == w.rear:
					front.append(p)
			if not front.is_empty():
				ports = front
			elif w.rear:
				# No authored rear port: use a rear surface, never a forward barrel.
				out.append(view.impact_location(w.loc, true))
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
