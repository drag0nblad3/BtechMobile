class_name BattleScars
extends Node3D
## Cosmetic battlefield history: hex scorch and dark wrecks for 3 turns.
## Every mark reconstructs from map state + BattleRecorder frames on resume/replay.

const MAX_SCORCHES := 140
const SMOULDER_TURNS := 3
var _state: GameState
var _units: UnitsLayer
var _scorches: Dictionary = {}
var _deaths: Dictionary = {}
var _smoke: Dictionary = {}


func setup(state: GameState, units: UnitsLayer, frames: Array = []) -> void:
	setup_history(state, units, BattleScarHistory.recover(frames))


func setup_history(state: GameState, units: UnitsLayer, history: Dictionary) -> void:
	_state = state
	_units = units
	_deaths = history.get("deaths", {}).duplicate()
	for c: Vector2i in history.get("scorches", {}):
		_scorch(c)
	for tile: MapTile in state.map.tiles.values():
		if tile.on_fire:
			_scorch(tile.coord)
	for u: Unit in state.all_units():
		if u.destroyed:
			_wreck(u.id)


## Smoke nodes are parented to unit views, not this scar layer.
func release_replay_smoke() -> void:
	for p: Node in _smoke.values():
		if is_instance_valid(p):
			if p.get_parent() != null:
				p.get_parent().remove_child(p)
			p.queue_free()
	_smoke.clear()


func on_event(e: GameEvent) -> void:
	var d := e.data
	match e.type:
		GameEvent.BUILDING:
			if d.get("kind", "") in ["fire", "inferno", "collapsed", "flattened"]:
				if d.get("coord") is Vector2i:
					_scorch(d["coord"])
		GameEvent.DAMAGE:
			if int(d.get("amount", 0)) >= 15:
				var u: Unit = _state.unit_by_id(int(d.get("unit_id", -1)))
				if u != null:
					_scorch(u.coord)
		GameEvent.UNIT_DESTROYED:
			var id := int(d.get("unit_id", -1))
			_deaths[id] = _state.turn
			_wreck(id)
		GameEvent.ACTIVE_SIDE, GameEvent.TURN_STARTED:
			_update_smoke()


func _scorch(c: Vector2i) -> void:
	if _scorches.has(c) or _scorches.size() >= MAX_SCORCHES:
		return
	var tile: MapTile = _state.map.get_tile(c)
	if tile == null:
		return
	var instance := MeshInstance3D.new()
	instance.name = "Scorch_%d_%d" % [c.x, c.y]
	var hex := CylinderMesh.new()
	hex.top_radius = HexLayout.HEX_SIZE * 0.75
	hex.bottom_radius = hex.top_radius
	hex.height = 0.015
	hex.radial_segments = 6
	instance.mesh = hex
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.12, 0.095, 0.09, 0.52)
	material.roughness = 1.0
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position = HexLayout.tile_top(tile) + Vector3(0, 0.015, 0)
	add_child(instance)
	_scorches[c] = instance


func _wreck(id: int) -> void:
	var u: Unit = _state.unit_by_id(id)
	var view: UnitView = _units.view_of(u) if u != null else null
	if view == null:
		return
	if view._model is VxMech:
		(view._model as VxMech).set_wrecked(true)
	if not _deaths.has(id):
		_deaths[id] = _state.turn
	if not _smoke.has(id):
		var p := _wreck_smoke(id)
		p.name = "WreckSmoke"
		p.position = Vector3(0, 0.4, 0)
		view.add_child(p)
		_smoke[id] = p
	_update_smoke()


func _update_smoke() -> void:
	for id: int in _smoke:
		var age := _state.turn - int(_deaths.get(id, _state.turn))
		(_smoke[id] as GPUParticles3D).emitting = age <= SMOULDER_TURNS


func _wreck_smoke(id: int) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 12
	p.lifetime = 1.5
	p.use_fixed_seed = true
	p.seed = id * 1301
	p.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 4, 4))
	var flow := ParticleProcessMaterial.new()
	flow.direction = Vector3.UP
	flow.spread = 30
	flow.initial_velocity_min = 0.3
	flow.initial_velocity_max = 0.75
	flow.gravity = Vector3(0, 0.6, 0)
	p.process_material = flow
	var quad := QuadMesh.new()
	quad.size = Vector2(0.22, 0.22)
	var ink := StandardMaterial3D.new()
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	ink.albedo_color = Color(0.25, 0.23, 0.22, 0.38)
	quad.material = ink
	p.draw_pass_1 = quad
	return p
