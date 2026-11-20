class_name BattleEnvironment
extends RefCounted
## Sky, ambient light and sun for the battlefield.


static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "Environment"
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.32, 0.45, 0.62)
	sky_mat.sky_horizon_color = Color(0.7, 0.72, 0.7)
	sky_mat.ground_bottom_color = Color(0.12, 0.11, 0.1)
	sky_mat.ground_horizon_color = Color(0.5, 0.5, 0.46)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	root.add_child(sun)
	return root
