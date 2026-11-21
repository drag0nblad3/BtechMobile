class_name FireProps
extends RefCounted
## Burning hexes: a glowing flame block on the ground (or roof) and a pale
## smoke column above it, two levels tall; fog banks as pale columns.

const FLAME_INSET := 0.6
const SMOKE_INSET := 0.85


static func build(map: BattleMap) -> Node3D:
	var root := Node3D.new()
	root.name = "Fires"
	var flame_mesh := HexMesh.prism(HexLayout.HEX_SIZE * FLAME_INSET)
	var smoke_mesh := HexMesh.prism(HexLayout.HEX_SIZE * SMOKE_INSET)
	var flame := _material(Color(1.0, 0.45, 0.1, 0.85), true)
	var smoke := _material(Color(0.55, 0.55, 0.55, 0.35), false)
	var fog := _material(Color(0.85, 0.88, 0.9, 0.3), false)
	for t: MapTile in map.tiles.values():
		if t.fog > 0 and not map.windy:  # fog banks (Obscurant), two levels tall
			root.add_child(_block(smoke_mesh, fog, HexLayout.tile_top(t), Obscurant.HEIGHT * HexLayout.LEVEL_HEIGHT * (0.6 + 0.4 * t.fog)))
		if not t.on_fire:
			continue
		var base := HexLayout.tile_top(t)
		if t.building != null:
			base.y += t.building.height * HexLayout.LEVEL_HEIGHT
		var fh := 0.25 * HexLayout.LEVEL_HEIGHT
		root.add_child(_block(flame_mesh, flame, base, fh))
		var sh := Fire.SMOKE_HEIGHT * HexLayout.LEVEL_HEIGHT
		root.add_child(_block(smoke_mesh, smoke, base + Vector3(0, fh, 0), sh))
	return root


static func _block(mesh: Mesh, mat: Material, at: Vector3, h: float) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.transform = Transform3D(Basis.from_scale(Vector3(1, h, 1)), at + Vector3(0, h, 0))
	return inst


static func _material(c: Color, glow: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if glow else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if glow:
		m.emission_enabled = true
		m.emission = Color(1.0, 0.5, 0.1)
	return m
