class_name CinematicDirector
extends Node
## Presentation-only camera director. Reacts to resolved combat events; never
## pauses the controller, changes a unit, or consumes battle RNG.
## Manual gestures suspend the director until the next meaningful action.

const HOLD_ACTION := 1.25
const HOLD_IMPACT := 1.9
const MAX_QUEUE := 4

var rig: CameraRig
var units: UnitsLayer
var enabled := false
var _return_pose: Dictionary = {}
var _queue: Array[Dictionary] = []
var _hold := 0.0
var _manual := 0.0
var _tracking := -1


func setup(camera_rig: CameraRig, unit_layer: UnitsLayer) -> void:
	rig = camera_rig
	units = unit_layer


func set_enabled(on: bool) -> void:
	if enabled == on:
		return
	enabled = on
	_queue.clear()
	_hold = 0.0
	_manual = 0.0
	_tracking = -1
	if on:
		_return_pose = rig.capture_pose()
	else:
		rig.restore_pose(_return_pose)


func manual_input() -> void:
	if not enabled:
		return
	_manual = 3.0
	_hold = 0.0
	_tracking = -1
	_queue.clear()


func on_event(e: GameEvent) -> void:
	if not enabled:
		return
	var d := e.data
	var shot := {}
	var urgent := false
	match e.type:
		GameEvent.UNIT_MOVED, GameEvent.DISPLACED:
			shot = {"kind": "follow", "unit_id": int(d.get("unit_id", -1))}
		GameEvent.WEAPON_FIRED, GameEvent.PHYSICAL:
			shot = {"kind": "pair", "unit_id": int(d.get("attacker_id", -1)),
					"target_id": int(d.get("target_id", -1))}
		GameEvent.AMMO_EXPLOSION, GameEvent.UNIT_DESTROYED, GameEvent.FALL:
			shot = {"kind": "impact", "unit_id": int(d.get("unit_id", -1))}
			urgent = true
	if shot.is_empty():
		return
	# A committed action takes priority over earlier manual navigation.
	_manual = 0.0
	if urgent:
		_queue.clear()
		_hold = 0.0
		_tracking = -1
	if _queue.size() >= MAX_QUEUE:
		_queue.pop_front()
	_queue.append(shot)
	if _hold <= 0.0:
		_next_shot()


func _process(delta: float) -> void:
	if not enabled:
		return
	if _manual > 0.0:
		_manual = maxf(0.0, _manual - delta)
		return
	if _tracking >= 0:
		var v: UnitView = units.views.get(_tracking)
		if v != null and v.visible and units.is_busy():
			rig.focus(v.global_position)
			_hold = maxf(_hold, 0.4)
		else:
			_tracking = -1
	_hold = maxf(0.0, _hold - delta)
	if _hold <= 0.0 and not _queue.is_empty():
		_next_shot()


func _next_shot() -> void:
	while not _queue.is_empty():
		var shot: Dictionary = _queue.pop_front()
		var id := int(shot["unit_id"])
		var v: UnitView = units.views.get(id)
		if v == null or not v.visible:
			continue
		var at := v.global_position
		var yaw := float(rig.capture_pose()["yaw"])
		match shot["kind"]:
			"follow":
				_tracking = id
				rig.cinematic_frame(at, 10.5, yaw + 0.22, deg_to_rad(42.0))
				_hold = HOLD_ACTION
			"pair":
				var other: UnitView = units.views.get(int(shot["target_id"]))
				if other != null and other.visible:
					var target := other.global_position
					var span := at.distance_to(target)
					var middle := at.lerp(target, 0.5)
					var facing := atan2(target.x - at.x, target.z - at.z)
					rig.cinematic_frame(middle, clampf(6.5 + span * 1.45, 8.0, 24.0),
							facing + 0.65, deg_to_rad(40.0))
				else:
					rig.cinematic_frame(at, 9.0, yaw + 0.20, deg_to_rad(40.0))
				_hold = HOLD_ACTION
			"impact":
				rig.cinematic_frame(at, 7.8, yaw + 0.28, deg_to_rad(36.0))
				_hold = HOLD_IMPACT
		return
