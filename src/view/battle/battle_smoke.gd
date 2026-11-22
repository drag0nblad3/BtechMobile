class_name BattleSmoke
extends Node3D
## Record-sheet-driven vent steam and ruined-location smoke.
## Reconstructed on scene load; never decides damage or changes Unit state.

const EMITTER_LIMIT := 30
var _state: GameState
var _units: UnitsLayer
var _scars: Dictionary = {}
var _vents: Dictionary = {}
var _glows: Dictionary = {}


func setup(state: GameState, units: UnitsLayer) -> void:
	_state = state
	_units = units
	restore()


func restore() -> void:
	for u: Unit in _state.all_units():
		for loc in Location.COUNT:
			if u.is_location_destroyed(loc):
				scar(u.id, loc)
		update_heat(u.id)


func scar(unit_id: int, loc: int) -> void:
	var key := "%d:%d" % [unit_id, loc]
	if _scars.has(key) or _scars.size() >= EMITTER_LIMIT:
		return
	var u: Unit = _state.unit_by_id(unit_id)
	var view: UnitView = _units.view_of(u) if u != null else null
	if view == null:
		return
	var mist := _emitter(Color("#464749", 0.6), 14, 0.20)
	mist.name = "WoundSmoke_%s" % key
	view.add_child(mist)
	mist.position = view.to_local(view.impact_location(loc, false))
	_scars[key] = mist


func update_heat(unit_id: int) -> void:
	var u: Unit = _state.unit_by_id(unit_id)
	var view: UnitView = _units.view_of(u) if u != null else null
	if view == null or u.def.is_support():
		return
	if not _vents.has(unit_id):
		var steam := _emitter(Color("#d7dedf", 0.26), 11, 0.12)
		steam.name = "HeatSteam"
		steam.position = Vector3(0, 1.1, 0)
		view.add_child(steam)
		_vents[unit_id] = steam
		var glow := OmniLight3D.new()
		glow.name = "ReactorGlow"
		glow.position = Vector3(0, 1.05, 0)
		glow.light_color = Color("#ff5237")
		glow.omni_range = 2.0
		glow.shadow_enabled = false
		view.add_child(glow)
		_glows[unit_id] = glow
	var level := float(u.heat)
	(_vents[unit_id] as GPUParticles3D).emitting = level >= 5.0 and not u.destroyed
	(_glows[unit_id] as OmniLight3D).light_energy = clampf((level - 5.0) / 24.0, 0.0, 0.75)


func _emitter(color: Color, amount: int, width: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = 1.6
	p.explosiveness = 0.0
	p.emitting = true
	p.use_fixed_seed = true
	p.seed = hash("%s:%d:smoke" % [str(color), amount])
	p.visibility_aabb = AABB(Vector3(-2, 0, -2), Vector3(4, 4, 4))
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 24.0
	process.initial_velocity_min = 0.3
	process.initial_velocity_max = 0.7
	process.gravity = Vector3(0, 0.7, 0)
	process.color = color
	p.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(width, width)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = color
	quad.material = mat
	p.draw_pass_1 = quad
	return p
