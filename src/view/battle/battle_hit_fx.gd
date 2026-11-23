class_name BattleHitFx
extends Node3D
## Dice-authoritative location impacts, camera kick and visible heat.
## The GameEvent's loc/rear and transfer steps are the only hit sources.

var _state: GameState
var _units: UnitsLayer
var _camera: CameraRig
var smoke := BattleSmoke.new()
var numbers := BattleDamageNumbers.new()
var _hits := 0


func setup(state: GameState, units: UnitsLayer) -> void:
	_state = state
	_units = units
	add_child(smoke)
	smoke.setup(state, units)
	add_child(numbers)


func attach_camera(camera: CameraRig) -> void:
	_camera = camera


func play(e: GameEvent) -> void:
	match e.type:
		GameEvent.DAMAGE:
			var steps: Array = e.data.get("steps", [])
			if steps.is_empty():
				_impact(e.data)
			else:
				for s: Dictionary in steps:
					var info := e.data.duplicate()
					info["loc"] = s.get("loc", info.get("loc", -1))
					info["rear"] = s.get("rear", info.get("rear", false))
					info["breached"] = s.get("breached", false)
					info["destroyed"] = s.get("destroyed", false)
					_impact(info)
			_damage_popup(e.data)  # Once per damage packet, not per transfer location.
		GameEvent.HEAT:
			smoke.update_heat(int(e.data.get("unit_id", -1)))
		GameEvent.UNIT_DESTROYED:
			_shake(int(e.data.get("unit_id", 0)), 0.38)
		GameEvent.FALL:
			_shake(int(e.data.get("unit_id", 0)), 0.25)


func _impact(d: Dictionary) -> void:
	var id := int(d.get("unit_id", -1))
	var loc := int(d.get("loc", -1))
	if loc < 0 or loc >= Location.COUNT:
		return
	var unit: Unit = _state.unit_by_id(id)
	var view: UnitView = _units.view_of(unit) if unit != null else null
	if view == null or not view.visible:
		return
	var point := view.impact_location(loc, bool(d.get("rear", false)))
	_hits += 1
	var amount := int(d.get("amount", 0))
	var seed := id * 119 + loc * 37 + _hits * 501 + int(d.get("rear", false)) * 79
	VxBlast.spawn(self, point, "impact", seed)
	if d.get("breached", false) or d.get("destroyed", false):
		smoke.scar(id, loc)
	elif unit.is_location_destroyed(loc):
		smoke.scar(id, loc)
	var power := clampf(float(amount) / 35.0, 0.0, 0.25)
	if power > 0.1:
		_shake(seed, power)


## Show the event's resolved damage; never infer it from visual impacts.
func _damage_popup(d: Dictionary) -> void:
	if bool(d.get("covered", false)) or int(d.get("amount", 0)) <= 0:
		return
	var u: Unit = _state.unit_by_id(int(d.get("unit_id", -1)))
	var v: UnitView = _units.view_of(u) if u != null else null
	if v == null or not v.visible:
		return
	var loc := int(d.get("loc", -1))
	var at := v.impact_location(loc, bool(d.get("rear", false))) if loc >= 0 and loc < Location.COUNT else v.global_position + Vector3.UP
	numbers.spawn(at, int(d["amount"]))


func _shake(seed: int, intensity: float) -> void:
	if _camera != null and GameSettings.camera_shake:
		_camera.shake(intensity, seed)
