class_name BuildingProps
extends RefCounted
## Buildings as see-through hex blocks, so a 'Mech inside stays visible.
## Height follows the building's levels; color follows its class.

const INSET := 0.82
const ALPHA := 0.72


static func build(map: BattleMap) -> Node3D:
	var root := Node3D.new()
	root.name = "Buildings"
	var mesh := HexMesh.prism(HexLayout.HEX_SIZE * INSET)
	var mats := {}  # BuildingType -> Material
	for t: MapTile in map.tiles.values():
		if t.building == null:
			continue
		var h := t.building.height * HexLayout.LEVEL_HEIGHT
		var inst := MeshInstance3D.new()
		inst.mesh = mesh
		inst.transform = Transform3D(Basis.from_scale(Vector3(1, h, 1)),
				HexLayout.tile_top(t) + Vector3(0, h, 0))
		if not mats.has(t.building.type):
			mats[t.building.type] = _material(t.building.type.color)
		inst.material_override = mats[t.building.type]
		root.add_child(inst)
	return root


static func _material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c, ALPHA)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.9
	return m
