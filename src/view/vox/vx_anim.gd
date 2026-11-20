class_name VxAnim
extends Node
## Animation hooks for a VxMech: walk/run, jump (with jets), fall, stand,
## punch, kick, torso twist + weapon fire, limb tumble, and smoke from
## damaged locations. The battle's UnitView would call these from
## GameEvents (UNIT_MOVED, FALL, STAND, PHYSICAL, WEAPON_FIRED).

signal finished

const WALK_CYCLE := 1.15
const RUN_CYCLE := 0.75
const SMOKE_EVERY := 0.45

var mech: VxMech
var walking := false
var phase := 0.0
var cycle := WALK_CYCLE
var crouch := 0.0       ## 0 standing .. 1 deep knee bend
var fallen := false
var kick_amount := [0.0, 0.0]
var _arm_busy := [false, false]
var _flames: Array[Node3D] = []
var _smoke_clock := 0.0


func setup(m: VxMech) -> void:
	mech = m


func walk(on: bool, run: bool = false) -> void:
	walking = on and not fallen
	cycle = RUN_CYCLE if run else WALK_CYCLE


## Ground speed that matches the planted foot, for whoever moves the 'Mech.
func ground_speed() -> float:
	return VxLegs.STRIDE / (VxGait.STANCE * cycle)


## Walks `distance` straight ahead (test scene; in battle UnitView moves it).
func walk_distance(distance: float, run: bool = false) -> void:
	walk(true, run)
	var tw := create_tween()
	tw.tween_property(mech, "position", mech.position - mech.basis.z * distance, distance / ground_speed())
	tw.tween_callback(_walk_done)


func _walk_done() -> void:
	walk(false)
	finished.emit()


func jump(offset: Vector3, height: float = 1.4) -> void:
	var from := mech.position
	var tw := create_tween()
	tw.tween_property(self, "crouch", 0.5, 0.25)
	tw.tween_callback(_jets.bind(true))
	tw.tween_method(_jump_step.bind(from, offset, height), 0.0, 1.0, 1.1)
	tw.tween_callback(_jets.bind(false))
	tw.tween_property(self, "crouch", 0.6, 0.08)
	tw.tween_property(self, "crouch", 0.0, 0.4).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(finished.emit)


func _jump_step(t: float, from: Vector3, offset: Vector3, height: float) -> void:
	mech.position = from + offset * t + Vector3.UP * 4.0 * height * t * (1.0 - t)
	crouch = 0.15 + 0.25 * sin(t * PI)  # legs tuck in the air


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


func fall() -> void:
	walking = false
	fallen = true
	var tw := create_tween().set_parallel()
	tw.tween_property(mech.body, "rotation:x", -1.45, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(mech.body, "position:y", 0.22, 0.7)
	tw.chain().tween_callback(_landed)


func _landed() -> void:
	var holder := mech.get_parent() if mech.get_parent() else mech
	VxFx.impact(holder, mech.global_position + mech.global_basis.z * -0.9, true)
	finished.emit()


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
	if not mech.model.can_punch or not mech.is_attached(s):
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


## Twists the torso toward `target`, fires every location, twists back.
func fire(locs: Array[int], target: Vector3, kind: String) -> void:
	var torso: Node3D = mech.pivots[mech.model.parts_at(Location.CT)[0]["name"]]
	var d := mech.to_local(target)
	var tw := create_tween()
	tw.tween_property(torso, "rotation:y", clampf(atan2(-d.x, -d.z), -1.0, 1.0), 0.25).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(VxVolley.fire.bind(self, mech, locs, target, kind))
	tw.tween_interval(0.9 if kind == "missile" else 0.5)
	tw.tween_property(torso, "rotation:y", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(finished.emit)


## A dropped limb falls over and comes to rest on the ground.
func tumble(limb: Node3D, dir: float) -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(limb, "global_position:y", 0.12, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(limb, "rotation:z", limb.rotation.z + dir * 1.45, 0.6)
	tw.tween_property(limb, "position:x", limb.position.x + dir * -0.25, 0.6)


func _process(delta: float) -> void:
	if mech == null:
		return
	_smoke(delta)
	for f in _flames:
		f.scale = Vector3.ONE * randf_range(0.8, 1.2)
	if fallen:
		return
	if walking:
		phase = fposmod(phase + delta / cycle, 1.0)
	mech.body.position.y = VxLegs.pose(mech, phase, walking, crouch, kick_amount)
	for side in 2:
		var s := mech.shoulders[side]
		if mech.model.can_punch and mech.is_attached(s) and not _arm_busy[side]:
			s.rotation.x = -sin((phase + 0.5 * side) * TAU) * 0.18 if walking else 0.0


## Damaged locations leak smoke; worse damage, thicker smoke.
func _smoke(delta: float) -> void:
	_smoke_clock += delta
	if _smoke_clock < SMOKE_EVERY or mech.get_parent() == null:
		return
	_smoke_clock = 0.0
	for loc: int in mech.wounded:
		if mech.is_attached(mech.part_at(loc)):
			VxTrails.wisp(mech.get_parent(), mech.location_point(loc), mech.wounded[loc])
