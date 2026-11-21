class_name ObjectiveMarkers
extends RefCounted
## Mission objectives on the map: a gold post on each objective hex and a
## faint gold plate on every hex inside its control radius.

const POST := Color(1.0, 0.8, 0.2, 0.95)
const AREA := Color(1.0, 0.8, 0.2, 0.18)
const INTEL := Color(0.3, 0.9, 1.0, 0.95)  ## Intel counters to scan (Urban Sweep).
const POTENTIAL := Color(0.85, 0.85, 0.85, 0.9)  ## Not yet known to be real (Objective Raid).


static func build(state: GameState) -> Node3D:
	var root := Node3D.new()
	root.name = "Objectives"
	var m := state.mission.def
	if m == null:
		return root
	var post_mesh := HexMesh.prism(HexLayout.HEX_SIZE * 0.25)
	var plate_mesh := HexMesh.prism(HexLayout.HEX_SIZE * 0.9)
	var post := _material(POST)
	var plate := _material(AREA)
	var intel := _material(INTEL)
	var maybe := _material(POTENTIAL)
	for o in m.objectives:
		if o.destroyed:
			continue
		for c: Vector2i in state.map.coords():
			if not o.in_radius(c):
				continue
			var top := HexLayout.tile_top(state.map.get_tile(c))
			root.add_child(_block(plate_mesh, plate, top + Vector3(0, 0.01, 0), 0.02))
		var t := state.map.get_tile(o.coord)
		if t != null:
			var top := HexLayout.tile_top(t)
			if t.building != null:  # above the roof so it stays visible
				top.y += HexLayout.LEVEL_HEIGHT * t.building.height
			root.add_child(_block(post_mesh, intel if o.kind == "intel" else (maybe if o.potential else post), top, HexLayout.LEVEL_HEIGHT * 1.5))
	return root


static func _block(mesh: Mesh, mat: Material, at: Vector3, h: float) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.transform = Transform3D(Basis.from_scale(Vector3(1, h, 1)), at + Vector3(0, h, 0))
	return inst


static func _material(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat
