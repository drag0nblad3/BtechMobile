class_name BattleEnvironment
extends RefCounted
## Low-cost sky, lighting and weather color grading for the battlefield.
## Visual conditions mirror the rules without affecting line-of-sight rolls.

static func build(conditions: Conditions = null) -> Node3D:
	var root := Node3D.new()
	root.name = "Environment"
	var night := conditions != null and conditions.night
	var snow := conditions != null and conditions.snowfall
	var rain := conditions != null and conditions.rain
	var hazy := conditions != null and conditions.low_visibility
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#101a36") if night else (
		Color("#65798a") if rain or snow else Color("#47769b"))
	sky_mat.sky_horizon_color = Color("#343f58") if night else (
		Color("#a2b4b9") if rain or snow else Color("#c4c6bc"))
	sky_mat.ground_bottom_color = Color("#080e17") if night else Color("#242c2e")
	sky_mat.ground_horizon_color = Color("#263044") if night else Color("#777d74")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.34 if night else (0.44 if rain or snow else 0.48)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# Distance haze adds depth without costly volumetric fog or a second light.
	if hazy or rain or snow:
		env.fog_enabled = true
		env.fog_light_color = Color("#4c5971") if night else (
			Color("#b7c5cc") if snow else Color("#929ca4"))
		env.fog_density = 0.026 if hazy else 0.009
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34, -43, 0) if night else Vector3(-52, -38, 0)
	sun.light_color = Color("#a9c8ea") if night else (
		Color("#dce7f5") if rain or snow else Color("#fff0d5"))
	sun.light_energy = 0.30 if night else (0.68 if rain or snow else 0.94)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65.0
	root.add_child(sun)
	return root
