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


func setup(spec: Dictionary, model: VxModel) -> void:
	part_name = spec["name"]
	name = part_name + "_mesh"
	loc = spec["loc"]
	original = spec["cells"]
	cells = original.duplicate()
	_pivot = spec["pivot"]
	_size = model.voxel_size
	_colors = model.colors
	_paintable.resize(model.roles.size())
	for i in model.roles.size():
		_paintable[i] = model.roles[i] == "armor"
	for material_name: String in model._mat:
		if _is_unpainted(String(material_name)):
			_paintable[int(model._mat[material_name])] = false
	material_override = shared_material()
	_setup_paint_space(model)


## Paint coordinates are bound to the articulated part, not the camera.
## Only the largest torso plates receive insignia; weapon pods stay clear.
func _setup_paint_space(model: VxModel) -> void:
	if original.is_empty():
		return
	var low := Vector3i(100000, 100000, 100000)
	var high := Vector3i(-100000, -100000, -100000)
	for c: Vector3i in original:
		low = Vector3i(mini(low.x, c.x), mini(low.y, c.y), mini(low.z, c.z))
		high = Vector3i(maxi(high.x, c.x), maxi(high.y, c.y), maxi(high.z, c.z))
	set_instance_shader_parameter("paint_origin", _pivot * _size)
	set_instance_shader_parameter("panel_min", Vector3(low) * _size)
	var span := Vector3(high - low + Vector3i.ONE) * _size
	set_instance_shader_parameter("panel_span", span)
	var largest: Dictionary = {}
	for candidate: Dictionary in model.parts_at(loc):
		if largest.is_empty() or candidate["cells"].size() > largest["cells"].size():
			largest = candidate
	var badge: bool = loc in [Location.LT, Location.RT] and String(largest.get("name", "")) == part_name
	badge = badge and span.x > 0.16 and span.y > 0.16
	set_instance_shader_parameter("badge_enabled", 1.0 if badge else 0.0)


## A barrel or cockpit may still be damageable armor in the source recipe;
## that must not make its gunmetal or glass into camouflaged plating.
static func _is_unpainted(mat_name: String) -> bool:
	var key := mat_name.to_lower()
	for token in ["gun", "barrel", "muzzle", "bore", "port", "glow", "light",
			"window", "glass", "cockpit", "sensor", "lens", "jet", "vent",
			"thruster", "exhaust", "grille", "engine", "piston", "joint",
			"frame", "structure", "dark"]:
		if key.contains(token):
			return true
	return false


func set_paint(mat: ShaderMaterial) -> void:
	_paint_material = mat
	material_override = mat


## Keeps every original cell except those in `removed`.
func set_removed(removed: Dictionary) -> void:
	var next := {}
	for c: Vector3i in original:
		if not removed.has(c):
			next[c] = original[c]
	if not removed.is_empty():
		for c: Vector3i in next.keys():  # Shot-loose voxels don't float.
			if DIRS.all(func(d: Vector3i) -> bool: return not next.has(c + d)):
				next.erase(c)
	if next.size() != cells.size():
		cells = next
		rebuild()


func set_wrecked(on: bool) -> void:
	if _wreck_material == null:
		_wreck_material = shared_material().duplicate()
		_wreck_material.albedo_color = Color(0.32, 0.3, 0.28)
	material_override = _wreck_material if on else (_paint_material if _paint_material else shared_material())


## Point in this part's local space for a grid coordinate.
func local_of(grid: Vector3) -> Vector3:
	return (grid - _pivot) * _size


func rebuild() -> void:
	var faces: Array = [{}, {}, {}, {}, {}, {}]  ## per direction: slice -> {Vector2i: Color}
	var count := 0
	for c: Vector3i in cells:
		var material_index: int = cells[c]
		var color: Color = _colors[material_index]
		var role_alpha := 1.0 if _paintable[material_index] else 0.25
		if _near_hole(c):
			color = color.lerp(SCORCH, 0.3)
		for f in 6:
			var d: Vector3i = DIRS[f]
			if cells.has(c + d):
				continue
			var axis := 0 if d.x != 0 else (1 if d.y != 0 else 2)
			var shaded := Color(color * SHADE[f], role_alpha * (0.5 if touching.has(c + d) else 1.0))
			var slices: Dictionary = faces[f]
			if not slices.has(c[axis]):
				slices[c[axis]] = {}
			slices[c[axis]][Vector2i(c[(axis + 1) % 3], c[(axis + 2) % 3])] = shaded
			count += 1
	mesh = VxMesher.build(faces, _pivot, _size)
	@warning_ignore("integer_division")
	triangles = mesh.get_faces().size() / 3 if mesh else 0
	faces_before_merge = count


func _near_hole(c: Vector3i) -> bool:
	if cells.size() == original.size():
		return false
	for d in DIRS:
		if original.has(c + d) and not cells.has(c + d):
			return true
	return false


## One material for every voxel part keeps draw state changes low on phones.
static func shared_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.75
		_material.metallic = 0.15
	return _material
