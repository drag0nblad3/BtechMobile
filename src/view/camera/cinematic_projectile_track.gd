class_name CinematicProjectileTrack
extends RefCounted
## Camera-only tracking of a rendered missile's brief travel; no dice or damage.

var _remaining := 0.0
var _attacker := -1
var _target := -1


func begin(attacker: int, target: int) -> void:
	_attacker = attacker
	_target = target
	_remaining = ShotFx.PROJECTILE_TIME


func stop() -> void:
	_remaining = 0.0
	_attacker = -1
	_target = -1


static func progress(remaining: float) -> float:
	return clampf(1.0 - remaining / ShotFx.PROJECTILE_TIME, 0.0, 1.0)


func tick(delta: float, rig: CameraRig, units: UnitsLayer) -> void:
	if _remaining <= 0.0:
		return
	_remaining = maxf(0.0, _remaining - delta)
	var start: UnitView = units.views.get(_attacker)
	var dest: UnitView = units.views.get(_target)
	if start == null or dest == null or not start.visible or not dest.visible:
		stop()
		return
	rig.focus(start.global_position.lerp(dest.global_position, progress(_remaining)))
