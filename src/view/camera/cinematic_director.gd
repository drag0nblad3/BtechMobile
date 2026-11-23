class_name CinematicDirector
extends Node
## Presentation-only camera director. Reacts to resolved combat events; never
## pauses the controller, changes a unit, or consumes battle RNG.
## Manual gestures own the camera until cinematics are explicitly toggled again.

const HOLD_ACTION := 0.85
const HOLD_IMPACT := 1.35
const RETURN_DELAY := 0.45
const MAX_QUEUE := 2

var rig: CameraRig
var units: UnitsLayer
var enabled := false
var _return_pose: Dictionary = {}
var _queue: Array[Dictionary] = []
var _hold := 0.0
var _manual := 0.0
var _tracking := -1
var _return_wait := 0.0
var _in_shot := false
var _projectile := CinematicProjectileTrack.new()


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
	_return_wait = 0.0
	_in_shot = false
	_projectile.stop()
	if on:
		_return_pose = rig.capture_pose()
	else:
		rig.restore_pose(_return_pose)


func manual_input() -> void:
	if not enabled:
		return
	_manual = 999999.0  # Player owns the camera until cinematic is toggled again.
	_hold = 0.0
	_tracking = -1
	_return_wait = 0.0
	_in_shot = false
	_projectile.stop()
	_queue.clear()


func on_event(e: GameEvent) -> void:
	if not enabled:
		return
	var d := e.data
	var shot := {}
	var urgent := false
	match e.type:
		GameEvent.UNIT_MOVED, GameEvent.DISPLACED:
			if units.is_busy() and CinematicShotPolicy.follow_move(d):
				shot = {"kind": "follow", "unit_id": int(d.get("unit_id", -1))}
		GameEvent.WEAPON_FIRED:
			# Reserve dramatic shots for consequential weapons, not every hit.
			var kind := CinematicShotPolicy.weapon_kind(d)
			if kind != "":
				shot = {"kind": kind, "unit_id": int(d.get("attacker_id", -1)),
					"target_id": int(d.get("target_id", -1))}
		GameEvent.PHYSICAL:
			if d.get("hit", false):
				shot = {"kind": "pair", "unit_id": int(d.get("attacker_id", -1)),
					"target_id": int(d.get("target_id", -1))}
		GameEvent.AMMO_EXPLOSION, GameEvent.UNIT_DESTROYED, GameEvent.FALL:
			shot = {"kind": "impact", "unit_id": int(d.get("unit_id", -1))}
			urgent = true
	if shot.is_empty():
		return
	# A committed action takes priority over earlier manual navigation.
	if _manual > 0.0:
		return  # Touch control always wins, including subsequent combat events.
	if urgent:
		_projectile.stop()
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
	_projectile.tick(delta, rig, units)
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
	elif _hold <= 0.0 and _queue.is_empty() and _in_shot and _tracking < 0:
		_return_wait += delta
		if _return_wait >= RETURN_DELAY:
			rig.restore_pose(_return_pose)
			_in_shot = false
			_return_wait = 0.0


func _next_shot() -> void:
	while not _queue.is_empty():
		var shot: Dictionary = _queue.pop_front()
		if not _in_shot:
			_return_pose = rig.capture_pose()
		_in_shot = true
		_return_wait = 0.0
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
			"pair", "missile":
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
				if shot["kind"] == "missile" and other != null and other.visible:
					_projectile.begin(id, int(shot["target_id"]))
			"impact":
				rig.cinematic_frame(at, 7.8, yaw + 0.28, deg_to_rad(36.0))
				_hold = HOLD_IMPACT
		return
