class_name VxAnim
extends Node
## Animation hooks for a VxMech: walk/run, jump (with jets), fall, stand,
## limb tumble and damage smoke. Attacks and hit reactions are in VxStrike.
## Motion is deliberately big and quick so it reads on a phone screen.
## The battle's UnitView would call these from GameEvents.

signal finished

const WALK_CYCLE := 0.8
const RUN_CYCLE := 0.55
const SMOKE_EVERY := 0.45
const FALLEN := -1.5

var mech: VxMech
var walking := false
var running := false
var phase := 0.0
var cycle := WALK_CYCLE
var crouch := 0.0        ## 0 standing .. 1 deep knee bend
var lean := 0.0          ## Extra forward pitch (jumps, lunges)
var flinch := Vector2.ZERO  ## Hit reaction: x = pitch, y = roll
var fallen := false
var declared_twist := 0.0
var declared_flip := false
var twisting := false    ## A strike or shot owns the torso yaw
var kick_amount := [0.0, 0.0]
var arm_busy := [false, false]
var _flames: Array[Node3D] = []
var _smoke_clock := 0.0


func setup(m: VxMech) -> void:
	mech = m


func walk(on: bool, run: bool = false) -> void:
	walking = on and not fallen
	running = run
	cycle = RUN_CYCLE if run else WALK_CYCLE


## Ground speed that matches the planted foot, for whoever moves the 'Mech.
func ground_speed() -> float:
	return (VxLegs.RUN_STRIDE if running else VxLegs.STRIDE) / (VxGait.STANCE * cycle)


## Walks `distance` straight ahead (test scene; in battle UnitView moves it).
func walk_distance(distance: float, run: bool = false) -> void:
	walk(true, run)
	var tw := create_tween()
	tw.tween_property(mech, "position", mech.position - mech.basis.z * distance, distance / ground_speed())
	tw.tween_callback(_walk_done)


func _walk_done() -> void:
	walk(false)
	finished.emit()


## Deep wind-up, a fast high arc leaning into the jump, a hard landing.
func jump(offset: Vector3, height: float = 2.2) -> void:
	var from := mech.position
	var tw := create_tween()
	tw.tween_property(self, "crouch", 0.95, 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_jets.bind(true))
	tw.tween_method(_jump_step.bind(from, offset, height), 0.0, 1.0, 0.85)
	tw.tween_callback(_jets.bind(false))
	tw.tween_callback(_dust)
	tw.tween_property(self, "crouch", 1.0, 0.05)
	tw.parallel().tween_property(self, "lean", 0.0, 0.05)
	tw.tween_property(self, "crouch", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(finished.emit)


func _jump_step(t: float, from: Vector3, offset: Vector3, height: float) -> void:
	mech.position = from + offset * t + Vector3.UP * 4.0 * height * t * (1.0 - t)
	crouch = 0.2 + 0.5 * sin(t * PI)  # legs tuck hard at the top
	lean = -0.35 * sin(t * PI)


func _jets(on: bool) -> void:
	for f in _flames:
		f.queue_free()
	_flames.clear()
	if not on:
		return
	for loc: int in mech.model.jets:
		if mech.is_attached(mech.part_at(loc)):
			for p in mech.jets(loc):
				_flames.append(VxTrails.jet_flame(mech.part_at(loc), p))


func _dust() -> void:
	if mech.get_parent():
		VxFx.impact(mech.get_parent(), mech.global_position + Vector3.UP * 0.05, true)


## Topples fast, slams down, bounces once.
func fall() -> void:
	walking = false
	fallen = true
	var tw := create_tween()
	tw.tween_property(mech.body, "rotation:x", FALLEN, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(mech.body, "rotation:z", 0.2, 0.42)
	tw.parallel().tween_property(mech.body, "position:y", 0.22, 0.42)
	tw.tween_callback(_landed)
	tw.tween_property(mech.body, "rotation:x", FALLEN + 0.14, 0.08).set_ease(Tween.EASE_OUT)
	tw.tween_property(mech.body, "rotation:x", FALLEN, 0.12).set_ease(Tween.EASE_IN)


func _landed() -> void:
	var holder := mech.get_parent() if mech.get_parent() else mech
	VxFx.impact(holder, mech.global_position + mech.global_basis.z * -0.9, true)
	finished.emit()


## Pushes up with a snap; a failed attempt rises halfway and crashes back.
func stand_up(ok: bool = true) -> void:
	var tw := create_tween()
	tw.tween_property(mech.body, "rotation:x", 0.0 if ok else -0.7, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mech.body, "rotation:z", 0.0, 0.45)
	if not ok:
		tw.tween_property(mech.body, "rotation:x", FALLEN, 0.25).set_ease(Tween.EASE_IN)
		tw.tween_callback(_landed)
	tw.tween_callback(_stand_done.bind(ok))


func _stand_done(ok: bool) -> void:
	fallen = not ok
	finished.emit()


func punch(side: int) -> void:
	VxStrike.punch(self, side)


func kick(side: int) -> void:
	VxStrike.kick(self, side)


func fire(locs: Array[int], target: Vector3, kind: String) -> void:
	VxStrike.fire(self, locs, target, kind)


func hit_reaction(loc: int, rear: bool, damage: int) -> void:
	VxStrike.flinch(self, loc, rear, damage)


## A dropped limb falls over and comes to rest on the ground.
func tumble(limb: Node3D, dir: float) -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(limb, "global_position:y", 0.12, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(limb, "rotation:z", limb.rotation.z + dir * 1.6, 0.5)
	tw.tween_property(limb, "position:x", limb.position.x + dir * -0.4, 0.5)


func _process(delta: float) -> void:
	if mech == null:
		return
	_smoke(delta)
	for f in _flames:
		f.scale = Vector3.ONE * randf_range(0.75, 1.3)
	if fallen:
		return
	if walking:
		phase = fposmod(phase + delta / cycle, 1.0)
	mech.body.position.y = VxLegs.pose(mech, phase, walking, crouch, kick_amount, running)
	var s := sin(phase * TAU) if walking else 0.0
	var gait_lean := (0.22 if running else 0.1) if walking else 0.0
	mech.body.rotation.x = -gait_lean - lean + flinch.x
	mech.body.rotation.z = s * 0.08 + flinch.y  # weight shifts onto the planted leg
	if not twisting:
		mech.pivots[mech.model.parts_at(Location.CT)[0]["name"]].rotation.y = declared_twist + s * 0.14
	for side in 2:
		var sh := mech.shoulders[side]
		if mech.model.can_punch and mech.is_attached(sh) and not arm_busy[side]:
			var code := "LA" if side == 0 else "RA"
			var ready: float = float(mech.model.ready_arm.get(code, 0.0))
			sh.rotation.z = float(mech.model.ready_roll.get(code, 0.0))
			sh.rotation.x = (PI if declared_flip else ready) + (-sin((phase + 0.5 * side) * TAU) * (
					0.8 if running else 0.55) if walking else 0.0)


## Damaged locations leak smoke; worse damage, thicker smoke.
func _smoke(delta: float) -> void:
	_smoke_clock += delta
	if _smoke_clock < SMOKE_EVERY or mech.get_parent() == null:
		return
	_smoke_clock = 0.0
	for loc: int in mech.wounded:
		if mech.is_attached(mech.part_at(loc)):
			VxTrails.wisp(mech.get_parent(), mech.location_point(loc), mech.wounded[loc])
