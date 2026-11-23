class_name VxStrike
extends RefCounted
## Attack moves and hit reactions for VxAnim: wind-up punches with a torso
## turn, snap kicks, fast torso twists to fire with recoil, and a sharp
## flinch away from each hit that springs back.


static func punch(a: VxAnim, side: int) -> void:
	var s := a.mech.shoulders[side]
	if not a.mech.model.can_punch or not a.mech.is_attached(s) or a.fallen:
		return
	a.arm_busy[side] = true
	a.twisting = true
	var torso := _torso(a)
	var turn := 0.5 if side == 1 else -0.5  # turn the punching shoulder forward
	var tw := a.create_tween()
	tw.tween_property(s, "rotation:x", -0.8, 0.1).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(torso, "rotation:y", -turn * 0.6, 0.1)
	tw.tween_property(s, "rotation:x", 1.75, 0.07).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(torso, "rotation:y", turn, 0.07)
	tw.parallel().tween_property(a, "lean", 0.18, 0.07)
	tw.tween_interval(0.1)
	var code := "LA" if side == 0 else "RA"
	var ready: float = float(a.mech.model.ready_arm.get(code, 0.0))
	tw.tween_property(s, "rotation:x", ready, 0.22).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(torso, "rotation:y", 0.0, 0.22)
	tw.parallel().tween_property(a, "lean", 0.0, 0.22)
	tw.tween_callback(_done.bind(a, side))


static func kick(a: VxAnim, side: int) -> void:
	if a.fallen:
		return
	var tw := a.create_tween()
	tw.tween_method(_kick_to.bind(a, side), 0.0, -0.4, 0.1)
	tw.parallel().tween_property(a, "lean", -0.12, 0.1)
	tw.tween_method(_kick_to.bind(a, side), -0.4, 1.3, 0.09).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(a, "lean", -0.25, 0.09)
	tw.tween_interval(0.08)
	tw.tween_method(_kick_to.bind(a, side), 1.3, 0.0, 0.25).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(a, "lean", 0.0, 0.25)
	tw.tween_callback(a.finished.emit)


static func _kick_to(v: float, a: VxAnim, side: int) -> void:
	a.kick_amount[side] = v


## Snaps the torso toward `target`, fires every location, and recoils.
static func fire(a: VxAnim, locs: Array[int], target: Vector3, kind: String) -> void:
	var torso := _torso(a)
	var d := a.mech.to_local(target)
	a.twisting = true
	var tw := a.create_tween()
	tw.tween_property(torso, "rotation:y", clampf(atan2(-d.x, -d.z), -1.1, 1.1), 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(VxVolley.fire.bind(a, a.mech, locs, target, kind))
	if kind != "laser":
		tw.tween_callback(_kickback.bind(a, kind, locs))
	tw.tween_interval(0.8 if kind == "missile" else 0.4)
	tw.tween_property(torso, "rotation:y", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_done.bind(a, -1))


## Heavy guns rock the whole 'Mech back; missile racks jerk upward.
static func _kickback(a: VxAnim, kind: String, locs: Array[int]) -> void:
	var tw := a.create_tween()
	tw.tween_property(a, "flinch:x", 0.22 if kind == "cannon" else 0.1, 0.05)
	tw.tween_property(a, "flinch:x", 0.0, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if kind != "missile":
		return
	for loc in locs:
		var joint: Node3D = a.mech.pivots[a.mech.model.parts_at(loc)[0]["name"]]
		if a.mech.is_attached(joint):
			var rack := a.create_tween()
			rack.tween_property(joint, "rotation:x", 0.35, 0.06)
			rack.tween_property(joint, "rotation:x", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Rocks away from the hit (bigger hits, bigger rock) and springs back.
static func flinch(a: VxAnim, loc: int, rear: bool, damage: int) -> void:
	var size := clampf(damage / 20.0, 0.25, 1.0)
	var pitch := (-0.3 if rear else 0.3) * size
	var roll := 0.0
	if loc in [Location.LT, Location.LA, Location.LL]:
		roll = -0.25 * size
	elif loc in [Location.RT, Location.RA, Location.RL]:
		roll = 0.25 * size
	var tw := a.create_tween()
	tw.tween_property(a, "flinch", Vector2(pitch, roll), 0.05).set_ease(Tween.EASE_OUT)
	tw.tween_property(a, "flinch", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


static func _torso(a: VxAnim) -> Node3D:
	return a.mech.pivots[a.mech.model.parts_at(Location.CT)[0]["name"]]


static func _done(a: VxAnim, side: int) -> void:
	if side >= 0:
		a.arm_busy[side] = false
	a.twisting = false
	a.finished.emit()
