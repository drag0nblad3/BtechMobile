class_name BattleWeather
extends Node3D
## Camera-following precipitation and mobile-safe sky/temperature accents.
## All weather visuals read Conditions; never alter terrain or dice.

const HEAT_SHADER := preload("res://src/view/shaders/heat_shimmer.gdshader")
const PARTICLE_RADIUS := 13.0
const MAX_SEARCHLIGHTS := 8

var _camera: Camera3D
var _precip: GPUParticles3D
var _heat: MeshInstance3D


func setup(c: Conditions, camera: Camera3D, units: UnitsLayer) -> void:
	_camera = camera
	if c.rain or c.snowfall:
		_precip = _make_precipitation(c)
		add_child(_precip)
	if c.heat > 0:
		_heat = MeshInstance3D.new()
		_heat.name = "HeatShimmer"
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(PARTICLE_RADIUS * 2.0, PARTICLE_RADIUS * 2.0)
		_heat.mesh = mesh
		var mat := ShaderMaterial.new()
		mat.shader = HEAT_SHADER
		mat.set_shader_parameter("strength", float(c.heat) / 3.0)
		_heat.material_override = mat
		_heat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_heat)
	if c.night:
		_searchlights(units)


func _make_precipitation(c: Conditions) -> GPUParticles3D:
	var snow := c.snowfall
	var particles := GPUParticles3D.new()
	particles.name = "Snow" if snow else "Rain"
	particles.amount = 110 if snow else 180
	particles.lifetime = 2.5 if snow else 1.0
	particles.explosiveness = 0.0
	particles.randomness = 0.25
	particles.visibility_aabb = AABB(Vector3(-PARTICLE_RADIUS, -8, -PARTICLE_RADIUS),
			Vector3(PARTICLE_RADIUS * 2, 16, PARTICLE_RADIUS * 2))
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(PARTICLE_RADIUS, 4, PARTICLE_RADIUS)
	material.direction = Vector3.DOWN
	material.spread = 5.0 if not snow else 40.0
	material.initial_velocity_min = 0.3 if snow else 4.0
	material.initial_velocity_max = 0.9 if snow else 7.0
	material.gravity = Vector3(0.6 if c.wind else 0.0, -1.1 if snow else -14.0, 0)
	material.color = Color("#dce9ff", 0.83 if snow else 0.48)
	particles.process_material = material
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.09, 0.09) if snow else Vector2(0.016, 0.26)
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	paint.albedo_color = Color("#f3f9ff", 0.8 if snow else 0.5)
	paint.no_depth_test = false
	mesh.material = paint
	particles.draw_pass_1 = mesh
	return particles


func _searchlights(units: UnitsLayer) -> void:
	var made := 0
	for view: UnitView in units.views.values():
		if view.unit.def.is_support() or view.unit.destroyed:
			continue
		var spot := SpotLight3D.new()
		spot.name = "NightSearchlight"
		spot.position = Vector3(0, 1.15, -0.27)
		spot.rotation_degrees.x = -12.0
		spot.light_color = Color("#c4deff")
		spot.light_energy = 0.5
		spot.spot_range = 5.5
		spot.spot_angle = 31.0
		spot.shadow_enabled = false
		view.add_child(spot)
		made += 1
		if made >= MAX_SEARCHLIGHTS:
			break


func _process(_delta: float) -> void:
	if _camera == null:
		return
	if _precip != null:
		_precip.global_position = _camera.global_position + Vector3(0, 2, 0)
	if _heat != null:
		_heat.global_position = _camera.global_position + Vector3(0, -5.5, -1.5)
