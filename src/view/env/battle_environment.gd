class_name BattleEnvironment
extends RefCounted
## Sky, ambient light and sun for the battlefield.


static func build(c: Conditions = null) -> Node3D:
	if c == null:
		c = Conditions.new()
	var root := Node3D.new()
	root.name = "Environment"
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#31465f")
	sky_mat.sky_horizon_color = Color("#9da9a8")
	sky_mat.ground_bottom_color = Color("#1b252b")
	sky_mat.ground_horizon_color = Color("#696e66")
	if c.night:
		sky_mat.sky_top_color = Color("#08111f")
		sky_mat.sky_horizon_color = Color("#28374f")
	elif c.heat > 0:
		sky_mat.sky_horizon_color = Color("#e2af7b")
	elif c.cold > 0:
		sky_mat.sky_horizon_color = Color("#afc7d4")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.15 if c.night else 0.48 if c.low_visibility else 0.52
	if c.low_visibility or c.rain or c.snowfall:
		env.fog_enabled = true
		env.fog_density = 0.034 if c.low_visibility else 0.013
		env.fog_light_color = Color("#8495aa") if c.night else Color("#acb9c6")
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 0.22 if c.night else 0.65 if c.low_visibility else 1.0
	sun.light_color = Color("#b6ceec") if c.night or c.cold > 0 else Color("#ffba88") if c.heat > 0 else Color("#ffe6c3")
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65.0
	root.add_child(sun)
	# A soft cool fill keeps shadow-side voxel silhouettes legible without
	# expensive screen-space ambient occlusion or an additional shadow map.
	var fill := DirectionalLight3D.new()
	fill.name = "SkyFill"
	fill.rotation_degrees = Vector3(-34, 143, 0)
	fill.light_energy = 0.13 if c.night else 0.22
	fill.light_color = Color("#a3c9e3")
	fill.shadow_enabled = false
	root.add_child(fill)
	var weather := BattleWeather.new()
	weather.name = "BattleWeather"
	root.add_child(weather)
	return root
