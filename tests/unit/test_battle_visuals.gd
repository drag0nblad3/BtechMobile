extends TestCase
## Cosmetic effects must stay isolated from rules and be cheap to instantiate.


func test_shot_styles_distinguish_weapon_families() -> void:
	check_eq(BattleShotFx.style_for("medium_laser"), "laser")
	check_eq(BattleShotFx.style_for("er_ppc"), "ppc")
	check_eq(BattleShotFx.style_for("lrm_15"), "missile")
	check_eq(BattleShotFx.style_for("srm_6"), "missile")
	check_eq(BattleShotFx.style_for("atm_9"), "missile")
	check_eq(BattleShotFx.style_for("flamer"), "flame")
	check_eq(BattleShotFx.style_for("ac_20"), "ballistic")
	check_eq(BattleShotFx.style_for("gauss_rifle"), "ballistic")


func test_beam_destinations_follow_hits_and_misses() -> void:
	var from := Vector3(0.0, 1.0, 0.0)
	var target := Vector3(6.0, 1.0, 8.0)
	check_eq(BattleShotFx.destination(from, target, true, 2), target)
	var miss_a := BattleShotFx.destination(from, target, false, 2)
	var miss_b := BattleShotFx.destination(from, target, false, 3)
	check(miss_a.distance_to(target) > 0.4, "miss should miss target model")
	check(miss_b.distance_to(target) > 0.4, "second miss should miss")
	check(miss_a.distance_to(miss_b) > 0.7, "misses fall to opposite sides")
	check_eq(BattleShotFx.MAX_ACTIVE, 30, "effect cap prevents unbounded weapon nodes")


func test_hex_outline_mesh_has_no_filled_center() -> void:
	var mesh := HexMesh.ring(0.93, 0.075)
	check_eq(mesh.get_surface_count(), 1)
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check_eq(vertices.size(), 36, "six ribbon segments, two triangles each")
	var shortest := 10.0
	var longest := 0.0
	for v in vertices:
		shortest = minf(shortest, Vector2(v.x, v.z).length())
		longest = maxf(longest, Vector2(v.x, v.z).length())
	check(shortest > 0.8, "outline leaves center clear")
	check(longest < 1.01, "outline stays in its hex")


func test_environment_responds_to_battlefield_conditions() -> void:
	var daylight := BattleEnvironment.build()
	var night := BattleEnvironment.build(Conditions.from_dict({"night": true}))
	var storm := BattleEnvironment.build(Conditions.from_dict(
			{"rain": true, "low_visibility": true}))
	var day_light := daylight.get_child(1) as DirectionalLight3D
	var night_light := night.get_child(1) as DirectionalLight3D
	check(night_light.light_energy < day_light.light_energy,
			"night should use dim moonlit lighting")
	var rainy := storm.get_child(0) as WorldEnvironment
	check(rainy.environment.fog_enabled, "storms add gentle distance haze")
	check(rainy.environment.fog_density > 0.02,
			"low visibility should have stronger haze")
	daylight.free()
	night.free()
	storm.free()
