class_name VxAnim
extends Node
## Animation hooks for a VxMech: walk/run gait, jump, fall, stand, punch,
## kick, torso twist and weapon recoil. The battle's UnitView would call
## these from GameEvents (UNIT_MOVED, FALL, STAND, PHYSICAL, WEAPON_FIRED).

signal finished

const WALK_CYCLE := 1.15
const RUN_CYCLE := 0.75
const STRIDE := 0.42
const LIFT := 0.12

var mech: VxMech
var walking := false
var phase := 0.0
var cycle := WALK_CYCLE
var crouch := 0.0      ## 0 standing .. 1 deep knee bend
var fallen := false
var kick_amount := [0.0, 0.0]  ## Per leg, 0..1 of a kick
var _arm_busy := [false, false]


func setup(m: VxMech) -> void:
	mech = m


func walk(on: bool, run: bool = false) -> void:
	walking = on and not fallen
	cycle = RUN_CYCLE if run else WALK_CYCLE


## Ground speed that matches the planted foot, for whoever moves the 'Mech.
func ground_speed() -> float:
	return STRIDE / (VxGait.STANCE * cycle)


## Walks `distance` straight ahead (showcase; in battle UnitView moves it).
func walk_distance(distance: float, run: bool = false) -> void:
	walk(true, run)
	var to := mech.position - mech.basis.z * distance
	var tw := create_tween()
	tw.tween_property(mech, "position", to, distance / ground_speed())
	tw.tween_callback(_walk_done)


func _walk_done() -> void:
	walk(false)
	finished.emit()


func jump(offset: Vector3, height: float = 1.4) -> void:
	var from := mech.position
	var tw := create_tween()
	tw.tween_property(self, "crouch", 0.45, 0.25)
	tw.tween_method(_jump_step.bind(from, offset, height), 0.0, 1.0, 1.0)
	tw.tween_property(self, "crouch", 0.55, 0.08)
	tw.tween_property(self, "crouch", 0.0, 0.35)
	tw.tween_callback(finished.emit)


func _jump_step(t: float, from: Vector3, offset: Vector3, height: float) -> void:
	mech.position = from + offset * t + Vector3.UP * 4.0 * height * t * (1.0 - t)
	crouch = 0.3


func fall() -> void:
	walking = false
	fallen = true
	var tw := create_tween().set_parallel()
	tw.tween_property(mech.body, "rotation:x", -1.45, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(mech.body, "position:y", 0.22, 0.7)
	tw.chain().tween_callback(finished.emit)


## A failed attempt rises halfway and slumps back.
func stand_up(ok: bool = true) -> void:
	var tw := create_tween()
	tw.tween_property(mech.body, "rotation:x", 0.0 if ok else -0.8, 0.8).set_trans(Tween.TRANS_SINE)
	if not ok:
		tw.tween_property(mech.body, "rotation:x", -1.45, 0.4).set_ease(Tween.EASE_IN)
	tw.tween_callback(_stand_done.bind(ok))


func _stand_done(ok: bool) -> void:
	fallen = not ok
	finished.emit()


func punch(side: int) -> void:
	var s := mech.shoulders[side]
	if not mech.is_attached(s):
		return
	_arm_busy[side] = true
	var tw := create_tween()
	tw.tween_property(s, "rotation:x", 1.5, 0.16).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.12)
	tw.tween_property(s, "rotation:x", 0.0, 0.35)
	tw.tween_callback(_arm_done.bind(side))


func _arm_done(side: int) -> void:
	_arm_busy[side] = false
	finished.emit()


func kick(side: int) -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float): kick_amount[side] = v, 0.0, 1.0, 0.22).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float): kick_amount[side] = v, 1.0, 0.0, 0.4)
	tw.tween_callback(finished.emit)


## Twists the torso toward `target`, fires, recoils, and twists back.
func fire(loc: int, target: Vector3, laser: bool) -> void:
	var torso: Node3D = mech.pivots[mech.model.parts_at(Location.CT)[0]["name"]]
	var d := mech.to_local(target)
	var yaw := clampf(atan2(-d.x, -d.z), -1.0, 1.0)
	var tw := create_tween()
	tw.tween_property(torso, "rotation:y", yaw, 0.25).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): _shoot(loc, target, laser))
	tw.tween_interval(0.5)
	tw.tween_property(torso, "rotation:y", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(finished.emit)


func _shoot(loc: int, target: Vector3, laser: bool) -> void:
	var holder := mech.get_parent() if mech.get_parent() else mech
	VxFx.shot(holder, mech.muzzle(loc), target, laser)
	var joint: Node3D = mech.pivots[mech.model.parts_at(loc)[0]["name"]]
	if laser or not mech.is_attached(joint):
		return
	var rest := joint.position
	var tw := create_tween()
	tw.tween_property(joint, "position", rest + Vector3(0, 0, 0.08), 0.05)
	tw.tween_property(joint, "position", rest, 0.3).set_trans(Tween.TRANS_ELASTIC)


## A dropped limb falls over and comes to rest on the ground.
func tumble(limb: Node3D, dir: float) -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(limb, "global_position:y", 0.12, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(limb, "rotation:z", limb.rotation.z + dir * 1.45, 0.6)
	tw.tween_property(limb, "position:x", limb.position.x + dir * -0.25, 0.6)


func _process(delta: float) -> void:
	if mech == null or fallen:
		return
	if walking:
		phase = fposmod(phase + delta / cycle, 1.0)
	var reach := mech.thigh + mech.shin
	var ankle_rest := mech.hip_height - reach
	var hip := ankle_rest + reach * (0.95 - 0.3 * crouch)
	var bob := absf(sin(phase * TAU)) * 0.015 if walking else 0.0
	mech.body.position.y = hip - mech.hip_height + bob
	for side in 2:
		var f := VxGait.foot(phase + 0.5 * side, STRIDE, LIFT) if walking else Vector2.ZERO
		f += Vector2(0.5 * kick_amount[side] * reach, 0.25 * kick_amount[side] * reach)
		_pose_leg(side, VxGait.solve(f.x, hip - ankle_rest - f.y, mech.thigh, mech.shin))
		var s := mech.shoulders[side]
		if mech.is_attached(s) and not _arm_busy[side]:
			s.rotation.x = -sin((phase + 0.5 * side) * TAU) * 0.18 if walking else 0.0


func _pose_leg(side: int, a: Vector3) -> void:
	if not mech.is_attached(mech.hips[side]):
		return
	mech.hips[side].rotation.x = a.x
	if mech.is_attached(mech.knees[side]):
		mech.knees[side].rotation.x = a.y
		mech.ankles[side].rotation.x = a.z
