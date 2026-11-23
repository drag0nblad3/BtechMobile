class_name VxMech
extends Node3D
## A voxel 'Mech built from a VxModel. Shows the rules' damage (VxDamage),
## drops destroyed limbs, and exposes the animation hooks (VxAnim) a
## UnitView calls. Never changes game state.

const MAX_DEBRIS := 6

var model: VxModel
var cache_path := ""
var side := 0
var body: Node3D               ## Whole-body pose root (falls, jumps).
var pivots: Dictionary = {}    ## part name -> Node3D joint
var parts: Dictionary = {}     ## part name -> VxPart
var hips: Array[Node3D] = [null, null]      ## [left, right]
var knees: Array[Node3D] = [null, null]
var ankles: Array[Node3D] = [null, null]
var hocks: Array[Node3D] = [null, null]     ## Reverse-jointed legs only
var shoulders: Array[Node3D] = [null, null]
var thigh := 0.0
var shin := 0.0
var tarsus := 0.0   ## Hock to ankle (digitigrade), 0 for plantigrade
var hip_height := 0.0
var damage: VxDamage
var anim: VxAnim
var lost: Dictionary = {}      ## Location -> true once its limb has dropped
var wounded: Dictionary = {}   ## Location -> share of structure gone (smoke)
var debris: Array[Node3D] = []
var _centers: Dictionary = {}  ## Location -> grid center of its first part


static func from_file(path: String) -> VxMech:
	var m := VxMech.new()
	m.cache_path = path
	m.model = VxRenderCache.model_at(path)
	m.build()
	return m


func build() -> void:
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	var size := model.voxel_size
	# Build all joints before attaching children. Authored add-on details
	# can legitimately precede their parent in the JSON and must still follow
	# the right knee/arm when it animates.
	for spec in model.parts:
		var joint := Node3D.new()
		joint.name = spec["name"]
		pivots[spec["name"]] = joint
	for spec in model.parts:
		var joint: Node3D = pivots[spec["name"]]
		var parent_name: String = spec.get("parent", "")
		var parent: Node3D = pivots.get(parent_name, body)
		var base: Vector3 = model.part(parent_name).get("pivot", Vector3.ZERO)
		joint.position = (spec["pivot"] - base) * size
		parent.add_child(joint)
		var part := VxPart.new()
		part.setup(spec, model)
		joint.add_child(part)
		parts[spec["name"]] = part
		var side := 0 if spec["loc"] in [Location.LT, Location.LA, Location.LL] else 1
		match spec["joint"]:
			"hip": hips[side] = joint
			"knee": knees[side] = joint
			"ankle": ankles[side] = joint
			"hock": hocks[side] = joint
			"shoulder": shoulders[side] = joint
	_mark_touching()
	if hips[0] and knees[0] and ankles[0]:
		thigh = absf(knees[0].position.y)
		var lower: Node3D = hocks[0] if hocks[0] else ankles[0]
		shin = absf(lower.position.y)
		tarsus = absf(ankles[0].position.y) if hocks[0] else 0.0
		hip_height = hips[0].position.y
	damage = VxDamage.new(model, parts)
	anim = VxAnim.new()
	anim.name = "Anim"
	add_child(anim)
	anim.setup(self)


## Every part learns which neighbor cells belong to other parts, then meshes.
func _mark_touching() -> void:
	var cached := VxRenderCache.geometry_at(cache_path) if cache_path != "" else {}
	if not cached.is_empty():
		for key: String in parts:
			var p: VxPart = parts[key]
			var entry: Dictionary = cached[key]
			p.mesh = entry["mesh"]
			p.triangles = entry["triangles"]
			p.faces_before_merge = entry["faces"]
			p.touching = entry["touching"]
		return
	var owner_of := {}
	for spec in model.parts:
		for c: Vector3i in spec["cells"]:
			owner_of[c] = spec["name"]
	for p: VxPart in parts.values():
		for c: Vector3i in p.original:
			for d in VxPart.DIRS:
				var o: String = owner_of.get(c + d, p.part_name)
				if o != p.part_name:
					p.touching[c + d] = true
		p.rebuild()
	if cache_path != "":
		VxRenderCache.remember(cache_path, parts)


## Matches the voxels to the unit's record sheet; drops destroyed limbs.
func show_unit(u: Unit) -> void:
	damage.show_unit(u)
	wounded.clear()
	for loc in Location.COUNT:
		var full := StructureTable.points(u.def.tonnage, loc, u.def.quad)
		if u.structure[loc] < full and not u.is_location_destroyed(loc):
			wounded[loc] = 1.0 - float(u.structure[loc]) / full
	for loc in [Location.LA, Location.RA, Location.LL, Location.RL]:
		if u.is_location_destroyed(loc) and not lost.has(loc):
			drop_limb(loc)
	set_wrecked(u.destroyed)


func set_side(value: int) -> void:
	side = value
	set_faction(GameSettings.paint_faction(side))


## Cosmetic paint never changes the model or the unit's record sheet.
func set_faction(faction: String) -> void:
	var paint := VxLivery.material_for(faction, side)
	for p: VxPart in parts.values():
		p.set_paint(paint)
	set_wrecked(false)


func set_wrecked(on: bool) -> void:
	for p: VxPart in parts.values():
		p.set_wrecked(on)


## World positions of a location's weapon muzzles (they move with the limb).
func muzzles(loc: int) -> Array[Vector3]:
	return _world_points(loc, model.muzzles.get(loc, [model.parts_at(loc)[0]["pivot"]]))


func jets(loc: int) -> Array[Vector3]:
	return _world_points(loc, model.jets.get(loc, []))


func part_at(loc: int) -> VxPart:
	return parts[model.parts_at(loc)[0]["name"]]


func _world_points(loc: int, grid: Array) -> Array[Vector3]:
	var part := part_at(loc)
	var out: Array[Vector3] = []
	for g: Vector3 in grid:
		out.append(part.to_global(part.local_of(g)))
	return out


## Center of a location's voxels in world space, for impact effects.
func location_point(loc: int) -> Vector3:
	var spec: Dictionary = model.parts_at(loc)[0]
	if not _centers.has(loc):
		var sum := Vector3.ZERO
		for c: Vector3i in spec["cells"]:
			sum += Vector3(c) + Vector3.ONE * 0.5
		_centers[loc] = sum / maxf(1.0, spec["cells"].size())
	var part: VxPart = parts[spec["name"]]
	return part.to_global(part.local_of(_centers[loc]))


func is_attached(n: Node) -> bool:
	return n != null and is_ancestor_of(n)


## The limb's top joint tumbles to the ground and stays as wreckage.
func drop_limb(loc: int) -> void:
	lost[loc] = true
	var top: Node3D = pivots[model.parts_at(loc)[0]["name"]]
	if not is_attached(top):
		return
	var live := is_inside_tree() and get_parent() != null
	var at := top.global_transform if live else Transform3D.IDENTITY
	top.get_parent().remove_child(top)
	debris.append(top)
	if debris.size() > MAX_DEBRIS:
		debris.pop_front().free()
	if not live:
		return  # Headless tests: just detach.
	get_parent().add_child(top)
	top.global_transform = at
	anim.tumble(top, 1.0 if loc in [Location.LA, Location.LL] else -1.0)


func voxel_count() -> int:
	var n := 0
	for p: VxPart in parts.values():
		n += p.cells.size()
	return n


func triangle_count() -> int:
	var n := 0
	for p: VxPart in parts.values():
		n += p.triangles
	return n


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for d in debris:
			if is_instance_valid(d):
				if d.is_inside_tree():
					d.queue_free()
				else:
					d.free()
