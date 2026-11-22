class_name PlaceholderAsset
extends RefCounted
## Blocky stand-ins for Battlefield Support Assets, facing -Z: tanks,
## hovercraft, wheeled vehicles, VTOLs, emplacements and infantry squads.
## Built from boxes like PlaceholderMech; swap for real models later.


static func build(def: UnitDef, side: int) -> Node3D:
	var voxel := VoxelAsset.build(def, side)
	if voxel != null:
		return voxel
	var root := Node3D.new()
	root.name = "PlaceholderAsset"
	var c := def.asset
	var body := PlaceholderMech._mat(PlaceholderMech.SIDE_COLORS[side % PlaceholderMech.SIDE_COLORS.size()])
	var dark := PlaceholderMech._mat(Color(0.18, 0.18, 0.2))
	if c.is_infantry():
		_squad(root, body, dark, 5 if c.kind == AssetCard.INFANTRY else 4, c.kind == AssetCard.BATTLE_ARMOR)
	elif c.kind == AssetCard.EMPLACEMENT:
		_box(root, Vector3(0.9, 0.35, 0.9), Vector3(0, 0.18, 0), body)
		_box(root, Vector3(0.08, 0.08, 0.5), Vector3(0, 0.25, -0.6), dark)
	elif c.kind == AssetCard.VTOL:
		_box(root, Vector3(0.3, 0.25, 0.8), Vector3(0, 0.9, 0), body)
		_box(root, Vector3(0.08, 0.08, 0.6), Vector3(0, 0.92, 0.65), body)
		_box(root, Vector3(1.2, 0.03, 0.08), Vector3(0, 1.08, 0), dark)
		_box(root, Vector3(0.08, 0.03, 1.2), Vector3(0, 1.08, 0), dark)
	else:
		_vehicle(root, body, dark, c)
	return root


static func _vehicle(root: Node3D, body: Material, dark: Material, c: AssetCard) -> void:
	match c.motive:
		"h":
			_box(root, Vector3(0.8, 0.12, 1.0), Vector3(0, 0.08, 0), dark)  # skirt
			_box(root, Vector3(0.66, 0.2, 0.86), Vector3(0, 0.24, 0), body)
		"w":
			for x in [-0.36, 0.36]:
				for z in [-0.3, 0.3]:
					_box(root, Vector3(0.1, 0.2, 0.2), Vector3(x, 0.1, z), dark)
			_box(root, Vector3(0.62, 0.24, 0.9), Vector3(0, 0.3, 0), body)
		_:
			_box(root, Vector3(0.14, 0.2, 1.0), Vector3(-0.33, 0.1, 0), dark)  # tracks
			_box(root, Vector3(0.14, 0.2, 1.0), Vector3(0.33, 0.1, 0), dark)
			_box(root, Vector3(0.56, 0.22, 0.92), Vector3(0, 0.26, 0), body)
	if not c.has("NOTUR"):
		_box(root, Vector3(0.36, 0.16, 0.36), Vector3(0, 0.45, 0.05), body)  # turret
		_box(root, Vector3(0.06, 0.06, 0.45), Vector3(0, 0.46, -0.3), dark)
	else:
		_box(root, Vector3(0.06, 0.06, 0.3), Vector3(0, 0.32, -0.55), dark)


static func _squad(root: Node3D, body: Material, dark: Material, n: int, armored: bool) -> void:
	var s := 1.4 if armored else 1.0
	for i in n:
		var a := TAU * i / n
		var p := Vector3(cos(a), 0, sin(a)) * 0.3
		_box(root, Vector3(0.08, 0.16, 0.06) * s, p + Vector3(0, 0.08 * s, 0), dark)
		_box(root, Vector3(0.1, 0.12, 0.07) * s, p + Vector3(0, 0.22 * s, 0), body)


static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	PlaceholderMech._box(parent, size, pos, mat, 1.25)
