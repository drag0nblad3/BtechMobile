class_name MineMarkers
extends RefCounted
## Minefield counters on the map (Minefields): a low red-and-dark plate on
## each mined hex, darker for denser fields.

const COLORS := {1: Color(0.9, 0.35, 0.2, 0.35), 2: Color(0.85, 0.2, 0.15, 0.5), 3: Color(0.7, 0.05, 0.05, 0.65)}


static func add(root: Node3D, state: GameState) -> void:
	var mesh := HexMesh.prism(HexLayout.HEX_SIZE * 0.6)
	for f: Dictionary in state.minefields:
		var t := state.map.get_tile(f["hex"])
		if t == null:
			continue
		var mat := StandardMaterial3D.new()
		mat.albedo_color = COLORS[int(f["density"])]
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var inst := MeshInstance3D.new()
		inst.mesh = mesh
		inst.material_override = mat
		inst.transform = Transform3D(Basis.from_scale(Vector3(1, 0.03, 1)), HexLayout.tile_top(t) + Vector3(0, 0.03, 0))
		root.add_child(inst)
