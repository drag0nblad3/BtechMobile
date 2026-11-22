class_name CinematicDirector
extends Node
## Presentation-only camera director. Reacts to resolved combat events; never
## pauses the controller, changes a unit, or consumes battle RNG.
## Manual gestures suspend the director until the next meaningful action.

const HOLD_ACTION := 0.78
const HOLD_IMPACT := 1.15
const MAX_QUEUE := 2

var rig: CameraRig
var units: UnitsLayer
var enabled := false
var _return_pose: Dictionary = {}
var _queue: Array[Dictionary] = []
var _hold := 0.0
var _manual := 0.0
var _tracking := -1
var _projectile_origin := -1
var _projectile_target := -1
var _projectile_time := 0.0
var _in_shot := false


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
	_projectile_time = 0.0
	_in_shot = false
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
	_projectile_time = 0.0
	_queue.clear()
	_in_shot = false
	# Keep the camera exactly where the user last aimed it on manual input.
	_return_pose = rig.capture_pose()


func on_event(e: GameEvent) -> void:
	if not enabled or _manual > 0.0:
		return
	var d := e.data
	if e.type == GameEvent.DAMAGE:
		var amount := int(d.get("amount", 0))
		if amount >= 9:
			rig.impact_kick(float(amount) / 50.0)
		return
	var shot := {}
	var urgent := false
	match e.type:
		GameEvent.UNIT_MOVED, GameEvent.DISPLACED:
			if int(d.get("mode", -1)) == MoveMode.Kind.JUMP or int(d.get("hexes", 0)) >= 5:
				shot = {"kind": "follow", "unit_id": int(d.get("unit_id", -1))}
		GameEvent.WEAPON_FIRED:
			if bool(d.get("hit", false)):
				var weapon := String(d.get("weapon_id", d.get("weapon", "")))
				var kind := ShotFx.style(weapon)
				var important := kind in ["ppc", "missile"] or "gauss" in weapon or "ac_20" in weapon
				if important or weapon == "":  # Keep legacy cinematic event callers.
					shot = {"kind": "missile" if kind == "missile" else "pair",
						"unit_id": int(d.get("attacker_id", -1)),
						"target_id": int(d.get("target_id", -1))}
		GameEvent.PHYSICAL:
			if bool(d.get("hit", false)):
				shot = {"kind": "pair", "unit_id": int(d.get("attacker_id", -1)),
					"target_id": int(d.get("target_id", -1))}
		GameEvent.AMMO_EXPLOSION, GameEvent.UNIT_DESTROYED, GameEvent.FALL:
			shot = {"kind": "impact", "unit_id": int(d.get("unit_id", -1))}
			urgent = true
	if shot.is_empty():
		return
	# Manual input has priority; actions arriving during navigation were ignored.
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
	if _projectile_time > 0.0:
		_projectile_time = maxf(0.0, _projectile_time - delta)
		var start: UnitView = units.views.get(_projectile_origin)
		var dest: UnitView = units.views.get(_projectile_target)
		if start != null and dest != null and start.visible and dest.visible:
			var progress := 1.0 - _projectile_time / ShotFx.PROJECTILE_TIME
			rig.focus(start.global_position.lerp(dest.global_position, progress))
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
	elif _hold <= 0.0 and _in_shot and _projectile_time <= 0.0:
		# Restore the tactical framing once the dramatic moment has passed.
		_in_shot = false
		_tracking = -1
		rig.restore_pose(_return_pose)


func _next_shot() -> void:
	while not _queue.is_empty():
		var shot: Dictionary = _queue.pop_front()
		if not _in_shot:
			_return_pose = rig.capture_pose()
			_in_shot = true
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
					_projectile_origin = id
					_projectile_target = int(shot["target_id"])
					_projectile_time = ShotFx.PROJECTILE_TIME
			"impact":
				rig.cinematic_frame(at, 7.8, yaw + 0.28, deg_to_rad(36.0))
				_hold = HOLD_IMPACT
		return
