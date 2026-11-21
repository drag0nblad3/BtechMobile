class_name GroundScatter
extends RefCounted
## Voxel clutter on hex tops so the ground isn't bare: grass tufts and
## flowers on clear ground, undergrowth in woods, rocks on rough ground,
## concrete chunks on rubble. One MultiMesh per prop variant; seeded per hex.

## Props per hex by terrain: [kind, count or chance below 1].
const MIX := {
	"clear": [["tuft", 3], ["flower", 0.25], ["rock", 0.12]],
	"light_woods": [["tuft", 2], ["bush", 1]],
	"heavy_woods": [["tuft", 1], ["bush", 2]],
	"rough": [["rock", 5], ["tuft", 2]],
	"rubble": [["chunk", 6]],
	"pavement": [["tuft", 0.2]],
}
const PLANTS := ["tuft", "flower", "bush"]


static func build(map: BattleMap) -> Node3D:
	var root := Node3D.new()
	root.name = "GroundScatter"
	var by_mesh := {}  # [kind, variant] -> Array[Transform3D]
	for t: MapTile in map.tiles.values():
		if not MIX.has(t.terrain.id) or t.building != null or t.surface == "snow":
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([t.coord, "scatter"])
		var top := HexLayout.tile_top(t)
		for entry: Array in MIX[t.terrain.id]:
			var amount: float = entry[1]
			var count := int(amount) if amount >= 1.0 else (1 if rng.randf() < amount else 0)
			for i in count:
				var a := rng.randf() * TAU
				var r := sqrt(rng.randf()) * 0.72
				var s := rng.randf_range(0.8, 1.3)
				var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s))
				var key := [entry[0], rng.randi() % VxPlants.VARIANTS]
				by_mesh.get_or_add(key, []).append(Transform3D(basis, top + Vector3(cos(a) * r, 0.0, sin(a) * r)))
	for key: Array in by_mesh:
		root.add_child(_layer(key, by_mesh[key]))
	return root


static func _layer(key: Array, xforms: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = VxPlants.mesh(key[0], key[1])
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = WoodsProps.material() if key[0] in PLANTS else VxGrid.material()
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst
