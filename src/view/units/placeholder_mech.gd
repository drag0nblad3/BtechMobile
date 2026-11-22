class_name PlaceholderMech
extends RefCounted
## Blocky stand-in 'Mech built from boxes, facing -Z. Size scales a little
## with tonnage. Swap for a glTF model later via UnitView.set_model().

const SIDE_COLORS := [Color(0.75, 0.2, 0.15), Color(0.2, 0.4, 0.8),
		Color(0.85, 0.7, 0.2), Color(0.3, 0.65, 0.3)]


static func build(def: UnitDef, side: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Placeholder"
	var s := 1.25 + def.tonnage / 250.0
	var body := _mat(SIDE_COLORS[side % SIDE_COLORS.size()])
	var dark := _mat(Color(0.18, 0.18, 0.2))
	var glass := _mat(Color(0.5, 0.9, 1.0), true)
	# legs
	_box(root, Vector3(0.16, 0.5, 0.2), Vector3(-0.17, 0.25, 0), dark, s)
	_box(root, Vector3(0.16, 0.5, 0.2), Vector3(0.17, 0.25, 0), dark, s)
	# torso, arms
	_box(root, Vector3(0.6, 0.42, 0.4), Vector3(0, 0.72, 0), body, s)
	_box(root, Vector3(0.14, 0.4, 0.18), Vector3(-0.39, 0.66, 0), body, s)
	_box(root, Vector3(0.14, 0.4, 0.18), Vector3(0.39, 0.66, 0), body, s)
	# cockpit on the front so facing is obvious
	_box(root, Vector3(0.24, 0.14, 0.12), Vector3(0, 0.84, -0.24), glass, s)
	# arm guns pointing forward
	_box(root, Vector3(0.07, 0.07, 0.3), Vector3(-0.39, 0.5, -0.18), dark, s)
	_box(root, Vector3(0.07, 0.07, 0.3), Vector3(0.39, 0.5, -0.18), dark, s)
	for arm_side in 2:
		var m := Marker3D.new()
		m.name = "Muzzle_LA" if arm_side == 0 else "Muzzle_RA"
		m.position = Vector3(-0.39 if arm_side == 0 else 0.39, 0.5, -0.35) * s
		root.add_child(m)
	return root


static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, s: float) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size * s
	mesh.material = mat
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos * s
	parent.add_child(inst)


static func _mat(c: Color, emissive: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	m.metallic = 0.3
	if emissive:
		m.emission_enabled = true
		m.emission = c * 0.6
	return m
