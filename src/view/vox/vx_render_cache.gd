class_name VxRenderCache
extends RefCounted
## Shares immutable recipe data and undamaged meshes across battle units.
## Each VxPart owns its mutable damage cells; a hit never mutates cached meshes.

static var _models: Dictionary = {}
static var _geometry: Dictionary = {}
static var _team_materials: Dictionary = {}


static func model_at(path: String) -> VxModel:
	if not _models.has(path):
		_models[path] = VxModel.load_file(path)
	return _models[path]


static func geometry_at(path: String) -> Dictionary:
	return _geometry.get(path, {})


static func remember(path: String, parts: Dictionary) -> void:
	var geometry := {}
	for name: String in parts:
		var p: VxPart = parts[name]
		geometry[name] = {"mesh": p.mesh, "triangles": p.triangles,
				"faces": p.faces_before_merge, "touching": p.touching}
	_geometry[path] = geometry


static func side_material(side: int) -> StandardMaterial3D:
	var index := posmod(side, PlaceholderMech.SIDE_COLORS.size())
	if not _team_materials.has(index):
		var mat := VxPart.shared_material().duplicate() as StandardMaterial3D
		# Vertex colors still define each chassis; the team wash is subdued.
		var tint: Color = PlaceholderMech.SIDE_COLORS[index]
		mat.albedo_color = Color.WHITE.lerp(tint, 0.24)
		_team_materials[index] = mat
	return _team_materials[index]
