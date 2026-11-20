class_name VxMech
extends Node3D
## A voxel 'Mech built from a VxModel. Shows the rules' damage (VxDamage),
## drops destroyed limbs, and exposes the animation hooks (VxAnim) a
## UnitView calls. Never changes game state.

const MAX_DEBRIS := 6

var model: VxModel
var body: Node3D               ## Whole-body pose root (falls, jumps).
var pivots: Dictionary = {}    ## part name -> Node3D joint
var parts: Dictionary = {}     ## part name -> VxPart
var hips: Array[Node3D] = [null, null]      ## [left, right]
var knees: Array[Node3D] = [null, null]
var ankles: Array[Node3D] = [null, null]
var shoulders: Array[Node3D] = [null, null]
var thigh := 0.0
var shin := 0.0
var hip_height := 0.0
var damage: VxDamage
var anim: VxAnim
var lost: Dictionary = {}      ## Location -> true once its limb has dropped
var debris: Array[Node3D] = []


static func from_file(path: String) -> VxMech:
	var m := VxMech.new()
	m.model = VxModel.load_file(path)
	m.build()
	return m


func build() -> void:
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	var size := model.voxel_size
	for spec in model.parts:
		var parent: Node3D = pivots.get(spec["parent"], body)
		var base: Vector3 = model.part(spec["parent"]).get("pivot", Vector3.ZERO)
		var joint := Node3D.new()
		joint.name = spec["name"]
		joint.position = (spec["pivot"] - base) * size
		parent.add_child(joint)
		pivots[spec["name"]] = joint
		var part := VxPart.new()
		part.setup(spec, model)
		joint.add_child(part)
		parts[spec["name"]] = part
		var side := 0 if spec["loc"] in [Location.LT, Location.LA, Location.LL] else 1
		match spec["joint"]:
			"hip": hips[side] = joint
			"knee": knees[side] = joint
			"ankle": ankles[side] = joint
			"shoulder": shoulders[side] = joint
	_mark_touching()
	if hips[0] and knees[0] and ankles[0]:
		thigh = absf(knees[0].position.y)
		shin = absf(ankles[0].position.y)
		hip_height = hips[0].position.y
	damage = VxDamage.new(model, parts)
	anim = VxAnim.new()
	anim.name = "Anim"
	add_child(anim)
	anim.setup(self)


## Every part learns which neighbor cells belong to other parts, then meshes.
func _mark_touching() -> void:
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


## Matches the voxels to the unit's record sheet; drops destroyed limbs.
func show_unit(u: Unit) -> void:
	damage.show_unit(u)
	for loc in [Location.LA, Location.RA, Location.LL, Location.RL]:
		if u.is_location_destroyed(loc) and not lost.has(loc):
			drop_limb(loc)
	set_wrecked(u.destroyed)


func set_wrecked(on: bool) -> void:
	for p: VxPart in parts.values():
		p.set_wrecked(on)


## World position of a weapon muzzle in a location (moves with the limb).
func muzzle(loc: int) -> Vector3:
	var spec: Dictionary = model.parts_at(loc)[0]
	var part: VxPart = parts[spec["name"]]
	return part.to_global(part.local_of(model.muzzles.get(loc, spec["pivot"])))


## Center of a location's voxels in world space, for impact effects.
func location_point(loc: int) -> Vector3:
	var spec: Dictionary = model.parts_at(loc)[0]
	var part: VxPart = parts[spec["name"]]
	var sum := Vector3.ZERO
	for c: Vector3i in spec["cells"]:
		sum += Vector3(c) + Vector3.ONE * 0.5
	return part.to_global(part.local_of(sum / maxf(1.0, spec["cells"].size())))


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
