class_name VxDamage
extends RefCounted
## Maps the record sheet onto voxels. Each location gets a fixed, seeded
## order in which its armor (front, rear) and structure voxels go, so the
## look is a pure function of armor and structure left: replays and reloads
## show the same scars. Cosmetic only; never feeds back into the rules.

const STRUCTURE_SHOWN := 0.7  ## Share of structure voxels gone just before the location dies.

var _orders: Dictionary = {}  ## "loc:kind" -> Array of [part name, cell]
var _parts: Dictionary        ## part name -> VxPart
var _model_id := ""


func _init(model: VxModel, parts: Dictionary) -> void:
	_parts = parts
	_model_id = model.id
	for loc in Location.COUNT:
		var front: Array = []
		var rear: Array = []
		var inner: Array = []
		for spec in model.parts_at(loc):
			var cells: Dictionary = spec["cells"]
			for c: Vector3i in cells:
				var entry := [spec["name"], c]
				if model.roles[cells[c]] == "structure":
					inner.append(entry)
				elif Location.HAS_REAR.has(loc) and c.z > 0:
					rear.append(entry)
				else:
					front.append(entry)
		_orders["%d:a" % loc] = _craters(front, "%d:a" % loc)
		_orders["%d:r" % loc] = _craters(rear, "%d:r" % loc)
		_orders["%d:s" % loc] = _craters(inner, "%d:s" % loc)


## Fractions are 0 (untouched) .. 1 (all gone). Rebuilds only changed parts.
func show_location(loc: int, armor_lost: float, rear_lost: float, structure_lost: float,
		destroyed: bool) -> void:
	var removed := {}  ## part name -> {cell: true}
	_take(removed, "%d:a" % loc, armor_lost)
	_take(removed, "%d:r" % loc, rear_lost)
	var limb := Location.is_arm(loc) or Location.is_leg(loc)
	var gone := structure_lost * STRUCTURE_SHOWN
	if destroyed:
		gone = 0.3 if limb else 0.95  # A lost limb drops off mostly whole.
	_take(removed, "%d:s" % loc, gone)
	for p: VxPart in _parts.values():
		if p.loc == loc:
			p.set_removed(removed.get(p.part_name, {}))


## Rules state -> picture for every location of `u`.
func show_unit(u: Unit) -> void:
	for loc in Location.COUNT:
		var full_s := StructureTable.points(u.def.tonnage, loc)
		show_location(loc, _lost(u.armor[loc], u.def.armor[loc]),
				_lost(u.rear_armor[loc], u.def.rear_armor[loc]),
				_lost(u.structure[loc], full_s), u.is_location_destroyed(loc))


func order_size(loc: int, kind: String) -> int:
	return _orders["%d:%s" % [loc, kind]].size()


func _take(removed: Dictionary, key: String, fraction: float) -> void:
	var order: Array = _orders[key]
	var n := roundi(clampf(fraction, 0.0, 1.0) * order.size())
	for i in n:
		var entry: Array = order[i]
		if not removed.has(entry[0]):
			removed[entry[0]] = {}
		removed[entry[0]][entry[1]] = true


## Orders cells as a run of craters: pick a seeded spot, take every
## remaining cell within a small radius (closest first), repeat.
func _craters(cells: Array, key: String) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_model_id + key)
	var left := cells.duplicate()
	var out: Array = []
	while not left.is_empty():
		var center := Vector3(left[rng.randi_range(0, left.size() - 1)][1])
		var radius := 2.2 + rng.randf() * 1.8
		var hit: Array = []
		var keep: Array = []
		for e: Array in left:
			(hit if Vector3(e[1]).distance_to(center) <= radius else keep).append(e)
		hit.sort_custom(func(a: Array, b: Array) -> bool:
				return Vector3(a[1]).distance_squared_to(center) < Vector3(b[1]).distance_squared_to(center))
		out.append_array(hit)
		left = keep
	return out


static func _lost(left: int, full: int) -> float:
	return 0.0 if full <= 0 else 1.0 - float(maxi(left, 0)) / float(full)
