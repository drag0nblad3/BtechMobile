class_name VxPart
extends MeshInstance3D
## One part of a voxel 'Mech: culled-face mesh of its cells, centered on its
## pivot. Cells next to shot-away voxels are drawn scorched.

const DIRS: Array[Vector3i] = [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP,
	Vector3i.DOWN, Vector3i.BACK, Vector3i.FORWARD]
const SHADE := [0.9, 0.9, 1.0, 0.7, 0.84, 0.97]
const SCORCH := Color(0.16, 0.12, 0.1)

static var _material: StandardMaterial3D
static var _wreck_material: StandardMaterial3D

var part_name := ""
var loc := -1
var original: Dictionary = {}  ## Vector3i -> material index, as built
var cells: Dictionary = {}     ## What is still there
var touching: Dictionary = {}  ## Cells of other parts; shared faces are inset so they don't flicker
var triangles := 0
var faces_before_merge := 0  ## Visible voxel faces (2 triangles each without merging)
var _pivot := Vector3.ZERO
var _size := 0.05
var _colors := PackedColorArray()
var _paintable: Array[bool] = []  ## Independent of the source's damage role.
var _paint_material: ShaderMaterial
var paint_bounds := AABB()
var _last_removed: Dictionary = {}


func setup(spec: Dictionary, model: VxModel, bounds: AABB = AABB()) -> void:
	part_name = spec["name"]
	name = part_name + "_mesh"
	loc = spec["loc"]
	original = spec["cells"]
	cells = original.duplicate()
	_pivot = spec["pivot"]
	_size = model.voxel_size
	_colors = model.colors
	_paintable = paint_mask(model)
	material_override = shared_material()
	paint_bounds = bounds if bounds.size != Vector3.ZERO else bounds_of(original)
	_setup_paint_space(model)


## Paint coordinates are bound to the articulated part, not the camera.
## Only the largest torso plates receive insignia; weapon pods stay clear.
func _setup_paint_space(model: VxModel) -> void:
	if original.is_empty():
		return
	set_instance_shader_parameter("paint_origin", _pivot * _size)
	set_instance_shader_parameter("panel_min", paint_bounds.position * _size)
	var span := paint_bounds.size * _size
	set_instance_shader_parameter("panel_span", span)
	var largest: Dictionary = {}
	for candidate: Dictionary in model.parts_at(loc):
		if largest.is_empty() or candidate["cells"].size() > largest["cells"].size():
			largest = candidate
	var badge: bool = loc in [Location.LT, Location.RT] and String(largest.get("name", "")) == part_name
	badge = badge and span.x > 0.16 and span.y > 0.16
	set_instance_shader_parameter("badge_enabled", 1.0 if badge else 0.0)


## Pure grid bounds, usable by the startup worker and shared mesh cache.
static func bounds_of(grid: Dictionary) -> AABB:
	if grid.is_empty():
		return AABB()
	var low := Vector3i(100000, 100000, 100000)
	var high := Vector3i(-100000, -100000, -100000)
	for c: Vector3i in grid:
		low = Vector3i(mini(low.x, c.x), mini(low.y, c.y), mini(low.z, c.z))
		high = Vector3i(maxi(high.x, c.x), maxi(high.y, c.y), maxi(high.z, c.z))
	return AABB(Vector3(low), Vector3(high - low + Vector3i.ONE))


## A barrel or cockpit may still be damageable armor in the source recipe;
## that must not make its gunmetal or glass into camouflaged plating.
static func paint_mask(model: VxModel) -> Array[bool]:
	var mask: Array[bool] = []
	mask.resize(model.roles.size())
	for i in model.roles.size():
		mask[i] = model.roles[i] == "armor"
	for material_name: String in model._mat:
		if _is_unpainted(material_name):
			mask[int(model._mat[material_name])] = false
	return mask


static func _is_unpainted(mat_name: String) -> bool:
	var key := mat_name.to_lower()
	for token in ["gun", "barrel", "muzzle", "bore", "port", "glow", "light",
			"window", "glass", "cockpit", "sensor", "lens", "jet", "vent",
			"thruster", "exhaust", "grille", "engine", "piston", "joint",
			"frame", "structure", "dark", "steel"]:
		if key.contains(token):
			return true
	return false


func set_paint(mat: ShaderMaterial) -> void:
	_paint_material = mat
	material_override = mat


## Keeps every original cell except those in `removed`.
func set_removed(removed: Dictionary) -> void:
	if removed == _last_removed:
		return
	_last_removed = removed.duplicate()
	var next := {}
	for c: Vector3i in original:
		if not removed.has(c):
			next[c] = original[c]
	if not removed.is_empty():
		for c: Vector3i in next.keys():  # Shot-loose voxels don't float.
			if DIRS.all(func(d: Vector3i) -> bool: return not next.has(c + d)):
				next.erase(c)
	if next != cells:
		cells = next
		rebuild()


func set_wrecked(on: bool) -> void:
	if not on:
		var normal: Material = _paint_material if _paint_material else shared_material()
		if material_override != normal:
			material_override = normal
		return
	if _wreck_material == null:
		_wreck_material = shared_material().duplicate()
		_wreck_material.albedo_color = Color(0.32, 0.3, 0.28)
	if material_override != _wreck_material:
		material_override = _wreck_material


## Point in this part's local space for a grid coordinate.
func local_of(grid: Vector3) -> Vector3:
	return (grid - _pivot) * _size


func rebuild() -> void:
	apply_surface(VxPreparedGeometry.surface(cells, original, touching, _colors,
			_paintable, _pivot, _size))


func apply_surface(data: Dictionary) -> void:
	var arrays: Array = data["arrays"]
	mesh = VxMesher.upload(arrays)
	@warning_ignore("integer_division")
	triangles = arrays[Mesh.ARRAY_VERTEX].size() / 3 if not arrays.is_empty() else 0
	faces_before_merge = int(data["faces"])


## One material for every voxel part keeps draw state changes low on phones.
static func shared_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.75
		_material.metallic = 0.15
	return _material
