class_name VoxelMech
extends Node3D
## Articulated biped using two-link gait IK and damageable voxel parts.

signal struck(part_name: String, removed: int, detached: bool)

var parts: Dictionary = {}  # String -> VoxelPart
var sockets: Dictionary = {}  # part name -> Node3D that detaches
var hips: Array[Node3D] = []
var knees: Array[Node3D] = []
var ankles: Array[Node3D] = []
var arms: Array[Node3D] = []
var walking := false
var gait_phase := 0.0
var travel_remaining := 0.0
var _chassis: Node3D
var debris: Array[RigidBody3D] = []


func _ready() -> void:
	build()
	stand()


func build() -> void:
	_chassis = Node3D.new()
	_chassis.name = "Frame"
	add_child(_chassis)
	var torso := VoxelPart.new()
	torso.name = "Torso"
	torso.position = Vector3(0, 1.87, 0)
	_chassis.add_child(torso)
	torso.armor_box(Vector3i(-8, -5, -4), Vector3i(7, 3, 4), 0, 1)
	torso.fill_box(Vector3i(-4, 0, -6), Vector3i(3, 3, -5), 2) # visor
	torso.fill_box(Vector3i(-2, -4, -6), Vector3i(1, -3, -5), 4)
	torso.fill_box(Vector3i(-4, 4, -2), Vector3i(3, 7, 2), 4) # raised cockpit
	torso.fill_box(Vector3i(-4, 5, -4), Vector3i(3, 6, -3), 2)
	torso.fill_box(Vector3i(-5, -4, -6), Vector3i(4, -2, -5), 0) # chest plate
	torso.fill_box(Vector3i(-10, 0, -4), Vector3i(-7, 3, 4), 4)
	torso.fill_box(Vector3i(6, 0, -4), Vector3i(9, 3, 4), 4)
	torso.fill_box(Vector3i(-8, 2, -3), Vector3i(-5, 4, 3), 5)
	torso.fill_box(Vector3i(4, 2, -3), Vector3i(7, 4, 3), 5)
	torso.seal()
	parts["torso"] = torso
	for side in 2:
		build_leg(side)
		build_arm(side)


func build_leg(side: int) -> void:
	var key := "left_leg" if side == 0 else "right_leg"
	var x := -0.38 if side == 0 else 0.38
	var hip := Node3D.new()
	hip.name = key + "_hip"
	hip.position = Vector3(x, 1.36, 0)
	_chassis.add_child(hip)
	hips.append(hip)
	var thigh := VoxelPart.new()
	thigh.name = key
	hip.add_child(thigh)
	thigh.armor_box(Vector3i(-3, -9, -3), Vector3i(3, -1, 3), 0, 1)
	thigh.fill_box(Vector3i(-4, -3, -4), Vector3i(4, -1, 4), 4)
	thigh.seal(-3)
	parts[key] = thigh
	sockets[key] = hip
	var knee := Node3D.new()
	knee.name = key + "_knee"
	knee.position.y = -VoxelGait.THIGH
	hip.add_child(knee)
	knees.append(knee)
	var shin := VoxelPart.new()
	shin.name = key + "_shin"
	knee.add_child(shin)
	shin.armor_box(Vector3i(-3, -9, -3), Vector3i(3, -1, 3), 0, 1)
	shin.fill_box(Vector3i(-4, -2, -4), Vector3i(4, 0, 4), 4)
	shin.seal()
	parts[key + "_shin"] = shin
	sockets[key + "_shin"] = knee
	var ankle := Node3D.new()
	ankle.name = key + "_ankle"
	ankle.position.y = -VoxelGait.SHIN
	knee.add_child(ankle)
	ankles.append(ankle)
	var foot := VoxelPart.new()
	foot.name = key + "_foot"
	ankle.add_child(foot)
	foot.armor_box(Vector3i(-4, -2, -9), Vector3i(4, 1, 4), 4, 1)
	foot.seal()
	parts[key + "_foot"] = foot


func build_arm(side: int) -> void:
	var key := "left_arm" if side == 0 else "right_arm"
	var x := -1.03 if side == 0 else 1.03
	var shoulder := Node3D.new()
	shoulder.name = key + "_shoulder"
	shoulder.position = Vector3(x, 2.04, 0)
	_chassis.add_child(shoulder)
	arms.append(shoulder)
	var arm := VoxelPart.new()
	arm.name = key
	shoulder.add_child(arm)
	arm.armor_box(Vector3i(-3, -8, -3), Vector3i(3, 1, 3), 0, 1)
	arm.fill_box(Vector3i(-4, -2, -4), Vector3i(4, 1, 4), 4)
	arm.fill_box(Vector3i(-2, -7, -11), Vector3i(2, -4, -4), 1)
	arm.fill_box(Vector3i(-3, -7, -11), Vector3i(3, -5, -10), 3)
	arm.seal(-2)
	parts[key] = arm
	sockets[key] = shoulder


func _process(delta: float) -> void:
	if not walking:
		return
	gait_phase = fposmod(gait_phase + delta / VoxelGait.CYCLE_SECONDS, 1.0)
	for side in 2:
		if hips[side].get_parent() != _chassis:
			continue
		var pose := VoxelGait.sample(gait_phase + 0.5 * side, hips[side].position.y)
		hips[side].rotation.x = pose.x
		if knees[side].get_parent() == hips[side]:
			knees[side].rotation.x = pose.y
			ankles[side].rotation.x = pose.z
		if arms[side].get_parent() == _chassis:
			arms[side].rotation.x = sin((gait_phase + side * 0.5) * TAU) * 0.16
	if travel_remaining > 0.0:
		var distance := minf(travel_remaining,
				VoxelGait.STRIDE / (VoxelGait.STANCE_FRACTION * VoxelGait.CYCLE_SECONDS) * delta)
		position.z -= distance
		travel_remaining -= distance
		if travel_remaining <= 0.0:
			walking = false
			stand()


func start_walk(distance: float = 3.0) -> void:
	position = Vector3(0, 0, 1.7)
	gait_phase = 0.0
	travel_remaining = distance
	walking = true


func stand() -> void:
	for side in 2:
		if hips[side].get_parent() == _chassis:
			hips[side].rotation.x = 0.25
			if knees[side].get_parent() == hips[side]:
				knees[side].rotation.x = -0.5
				ankles[side].rotation.x = 0.25
		if arms[side].get_parent() == _chassis:
			arms[side].rotation.x = 0.0


func shoot(origin: Vector3, direction: Vector3, radius: float = 0.23) -> Dictionary:
	var closest: Dictionary = {}
	var name_hit := ""
	for key: String in parts:
		var part: VoxelPart = parts[key]
		if not is_instance_valid(part) or part.cells.is_empty():
			continue
		var hit := part.pick_ray(origin, direction)
		if not hit.is_empty() and (closest.is_empty() or hit["distance"] < closest["distance"]):
			closest = hit
			name_hit = key
	if closest.is_empty():
		return {}
	var removed := hit_part(name_hit, closest["point"], radius)
	return {"part": name_hit, "point": closest["point"], "removed": removed}


func hit_part(key: String, point: Vector3, radius: float = 0.23) -> int:
	if not parts.has(key):
		return 0
	var part: VoxelPart = parts[key]
	var removed := part.erase_ball(point, radius)
	var snapped := false
	if removed > 0 and sockets.has(key):
		if part.joint_fraction() < 0.40 or part.cells.size() < 0.30 * part._original_count:
			detach(key)
			snapped = true
	struck.emit(key, removed, snapped)
	return removed


func detach(key: String) -> void:
	if not sockets.has(key):
		return
	var root: Node3D = sockets[key]
	if root.get_parent() != _chassis and not hips.has(root.get_parent()):
		return
	var old_transform := root.global_transform
	root.get_parent().remove_child(root)
	var body := RigidBody3D.new()
	body.name = key + "_wreck"
	get_tree().current_scene.add_child(body)
	body.global_transform = old_transform
	body.add_child(root)
	root.transform = Transform3D.IDENTITY
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.60, 0.80, 0.65)
	shape.shape = box
	shape.position.y = -0.25
	body.add_child(shape)
	debris.append(body)
	body.linear_velocity = Vector3(0.5 if key.begins_with("left") else -0.5, 0.3, -0.4)
	body.angular_velocity = Vector3(0.4, 0.5, 1.2)


func _exit_tree() -> void:
	for body in debris:
		if is_instance_valid(body):
			body.queue_free()


func remaining_voxels() -> int:
	var count := 0
	for part: VoxelPart in parts.values():
		count += part.cells.size()
	return count
