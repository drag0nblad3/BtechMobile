extends TestCase
## Climate art reads Conditions without changing gameplay.


func test_night_darkens_ambient_and_tints_sun() -> void:
	var normal := BattleEnvironment.build(Conditions.new())
	var night := BattleEnvironment.build(Conditions.from_dict({"night": true}))
	var clear_env := normal.get_child(0) as WorldEnvironment
	var dark_env := night.get_child(0) as WorldEnvironment
	check(dark_env.environment.ambient_light_energy < clear_env.environment.ambient_light_energy,
			"night should be darker")
	var sun := night.get_child(1) as DirectionalLight3D
	check(sun.light_energy < 0.5, "night is moon-lit rather than full sun")
	check(night.get_node_or_null("BattleWeather") != null, "night weather node")
	normal.free()
	night.free()


func test_fog_only_when_conditions_require_it() -> void:
	var clear := BattleEnvironment.build(Conditions.new())
	var fog := BattleEnvironment.build(Conditions.from_dict({"low_visibility": true}))
	var rain := BattleEnvironment.build(Conditions.from_dict({"rain": true}))
	check(not (clear.get_child(0) as WorldEnvironment).environment.fog_enabled, "clear day has no fog")
	check((fog.get_child(0) as WorldEnvironment).environment.fog_enabled, "low visibility fog")
	check((rain.get_child(0) as WorldEnvironment).environment.fog_enabled, "rain atmosphere")
	clear.free()
	fog.free()
	rain.free()


func test_precipitation_uses_a_bounded_gpu_emitter() -> void:
	var w := BattleWeather.new()
	var rain := w._make_precipitation(Conditions.from_dict({"rain": true}))
	var snow := w._make_precipitation(Conditions.from_dict({"snowfall": true, "wind": true}))
	check(rain.amount <= 180 and snow.amount <= 180, "bounded mobile particles")
	check(rain.process_material is ParticleProcessMaterial, "GPU process material")
	check((snow.process_material as ParticleProcessMaterial).gravity.x > 0.0, "wind drifts snow")
	rain.free()
	snow.free()
	w.free()


func test_cold_and_heat_tint_ground_cosmetically() -> void:
	var map_view := MapView.new()
	map_view.set_conditions(Conditions.from_dict({"cold": 2}))
	var cold := map_view.weather_tint
	map_view.set_conditions(Conditions.from_dict({"heat": 2}))
	check(cold != map_view.weather_tint, "heat and cold produce different color grades")
	map_view.set_conditions(Conditions.new())
	check_eq(map_view.weather_tint, Color.WHITE)
	map_view.free()
