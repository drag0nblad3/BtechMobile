class_name FireProps
extends RefCounted
## Burning hexes as voxel fire: glowing cubes that rise and shrink over
## the hex (or its roof) under a column of soot cubes two levels tall,
## all animated in vx_flame.gdshader. Fog banks stay pale columns.

const FLAME_SHADER := preload("res://src/view/shaders/vx_flame.gdshader")
const FLAMES := 34     ## Cubes per burning hex.
const SOOT := 14
const FLAME_SIZE := 0.12
const SOOT_SIZE := 0.13
const SMOKE_INSET := 0.85

static var _flame_mat: ShaderMaterial
static var _soot_mat: ShaderMaterial


static func build(map: BattleMap) -> Node3D:
	var root := Node3D.new()
	root.name = "Fires"
	var smoke_mesh := HexMesh.prism(HexLayout.HEX_SIZE * SMOKE_INSET)
	var fog := _fog_material()
	var bases: Array[Vector3] = []
	for t: MapTile in map.tiles.values():
		var cloud := Obscurant.cloud(t)
		if cloud > 0 and not map.windy:  # fog banks and Arrow IV smoke (Obscurant), two levels tall
			root.add_child(_block(smoke_mesh, fog, HexLayout.tile_top(t), Obscurant.HEIGHT * HexLayout.LEVEL_HEIGHT * (0.6 + 0.4 * cloud)))
		if not t.on_fire:
			continue
		var base := HexLayout.tile_top(t)
		if t.building != null:
			base.y += t.building.height * HexLayout.LEVEL_HEIGHT
		bases.append(base)
	if not bases.is_empty():
		root.add_child(_cubes(bases, FLAMES, FLAME_SIZE, 0.42, 0.1, flame_material()))
		root.add_child(_cubes(bases, SOOT, SOOT_SIZE, 0.3, 0.25, soot_material()))
	return root


## One MultiMesh of cubes over every burning hex; custom data drives the shader.
static func _cubes(bases: Array[Vector3], per_hex: int, size: float, spread: float,
		lift: float, mat: Material) -> MultiMeshInstance3D:
	var box := BoxMesh.new()
	box.size = Vector3.ONE * size
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = box
	mm.instance_count = bases.size() * per_hex
	var rng := RandomNumberGenerator.new()
	rng.seed = bases.size()
	for i in mm.instance_count:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * spread
		var p := bases[i / per_hex] + Vector3(cos(a) * r, lift + rng.randf() * 0.05, sin(a) * r)
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), p))
		mm.set_instance_custom_data(i, Color(rng.randf(), rng.randf_range(0.7, 1.3), rng.randf_range(0.01, 0.04), 0))
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst


static func flame_material() -> ShaderMaterial:
	if _flame_mat == null:
		_flame_mat = ShaderMaterial.new()
		_flame_mat.shader = FLAME_SHADER
	return _flame_mat


static func soot_material() -> ShaderMaterial:
	if _soot_mat == null:
		_soot_mat = ShaderMaterial.new()
		_soot_mat.shader = FLAME_SHADER
		_soot_mat.set_shader_parameter("smoke", true)
		_soot_mat.set_shader_parameter("rise", Fire.SMOKE_HEIGHT * HexLayout.LEVEL_HEIGHT)
	return _soot_mat


static func _block(mesh: Mesh, mat: Material, at: Vector3, h: float) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.transform = Transform3D(Basis.from_scale(Vector3(1, h, 1)), at + Vector3(0, h, 0))
	return inst


static func _fog_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.88, 0.9, 0.3)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
