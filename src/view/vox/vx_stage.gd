class_name VxStage
extends RefCounted
## Lighting, ground and a target post for the voxel showcase.


static func build(root: Node3D) -> Vector3:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("1b2430")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c4d0dc")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.5
	sun.directional_shadow_max_distance = 20.0
	root.add_child(sun)
	var hex := HexMesh.prism(HexLayout.HEX_SIZE * 0.97)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("3a4530")
	mat.roughness = 0.95
	for q in range(-3, 4):
		for r in range(-3, 4):
			if absi(q + r) > 3:
				continue
			var tile := MeshInstance3D.new()
			tile.mesh = hex
			tile.material_override = mat
			var p := HexLayout.to_world(Vector2i(q, r))
			tile.transform = Transform3D(Basis.from_scale(Vector3(1, 0.1, 1)), p)
			root.add_child(tile)
	var target := Vector3(1.8, 0.9, -4.5)
	var post := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 1.8, 0.5)
	post.mesh = box
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color("8a5a3a")
	post.material_override = pm
	post.position = target
	root.add_child(post)
	return target

