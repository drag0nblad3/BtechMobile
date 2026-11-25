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
var _detail := 1
var _model: VxModel


func _init(model: VxModel, parts: Dictionary) -> void:
	_parts = parts
	_model = model
	_model_id = model.id
	_detail = model.detail
	if not model.quality_report.has("fine_catalog"):
		_orders = model.damage_orders


## Generate only the requested region, and only when damage actually
## requires it. Traversal order and seed match the former eager build.
func _order(loc: int, kind: String) -> Array:
	var key := "%d:%s" % [loc, kind]
	if _orders.has(key):
		return _orders[key]
	var selected: Array = []
	for spec in _model.parts_at(loc):
		var cells: Dictionary = spec["cells"]
		for c: Vector3i in cells:
			var region := "a"
			if _model.roles[cells[c]] == "structure":
				region = "s"
			elif Location.HAS_REAR.has(loc) and c.z > 0:
				region = "r"
			if region == kind:
				selected.append([spec["name"], c])
	_orders[key] = _craters(selected, key)
	return _orders[key]


## Fractions are 0 (untouched) .. 1 (all gone). Rebuilds only changed parts.
func show_location(loc: int, armor_lost: float, rear_lost: float, structure_lost: float,
		destroyed: bool) -> void:
	var removed := {}  ## part name -> {cell: true}
	_take(removed, loc, "a", armor_lost)
	_take(removed, loc, "r", rear_lost)
	var limb := Location.is_arm(loc) or Location.is_leg(loc)
	var gone := structure_lost * STRUCTURE_SHOWN
	if destroyed:
		gone = 0.3 if limb else 0.95  # A lost limb drops off mostly whole.
	_take(removed, loc, "s", gone)
	for p: VxPart in _parts.values():
		if p.loc == loc:
			p.set_removed(removed.get(p.part_name, {}))


## Rules state -> picture for every location of `u`.
func show_unit(u: Unit) -> void:
	show_record(u.def, u.armor, u.rear_armor, u.structure)


func show_record(def: UnitDef, armor: Array, rear: Array, structure: Array) -> void:
	for loc in Location.COUNT:
		var full_s := StructureTable.points(def.tonnage, loc, def.quad)
		show_location(loc, _lost(armor[loc], def.armor[loc]),
				_lost(rear[loc], def.rear_armor[loc]),
				_lost(structure[loc], full_s), structure[loc] <= 0)


## Locate the first newly removed voxel in the same deterministic crater
## sequence the mesh will use at impact. No effect on the damage record.
func crater_point(u: Unit, step: Dictionary) -> Vector3:
	var loc := int(step.get("loc", -1))
	if loc < 0 or loc >= Location.COUNT:
		return Vector3.INF
	var back := bool(step.get("rear", false)) and Location.HAS_REAR.has(loc)
	var kind := "r" if back else "a"
	var full := u.def.rear_armor[loc] if back else u.def.armor[loc]
	var left := u.rear_armor[loc] if back else u.armor[loc]
	var pips := int(step.get("armor", 0))
	if pips <= 0:
		return Vector3.INF
	var order := _order(loc, kind)
	var start := roundi(_lost(left + pips, full) * order.size())
	var end := roundi(_lost(left, full) * order.size())
	if start >= end or start >= order.size():
		return Vector3.INF
	var entry: Array = order[start]
	var part: VxPart = _parts.get(entry[0])
	if not is_instance_valid(part) or not part.is_inside_tree():
		return Vector3.INF
	return part.to_global(part.local_of(Vector3(entry[1]) + Vector3.ONE * 0.5))


func order_size(loc: int, kind: String) -> int:
	return _order(loc, kind).size()


func _take(removed: Dictionary, loc: int, kind: String, fraction: float) -> void:
	if fraction <= 0.0:
		return
	var order := _order(loc, kind)
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
		var radius := (2.2 + rng.randf() * 1.8) * _detail
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
