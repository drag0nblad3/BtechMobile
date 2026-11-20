class_name VoxelMech
extends Node3D
## Damageable mech with selectable humanoid or three-link digitigrade gait.

signal struck(part_name: String, removed: int, detached: bool)

var profile_id := "prototype"
var upper_stability := 0.90  ## 1.0 = locked gun platform, 0.0 = full sway.
var parts: Dictionary = {}
var sockets: Dictionary = {}
var hips: Array = []
var knees: Array = []
var hocks: Array = []
var ankles: Array = []
var arms: Array = []
var walking := false
var gait_phase := 0.0
var travel_remaining := 0.0
var _chassis: Node3D
var _upper: Node3D
var _profile: Dictionary = {}
var debris: Array[RigidBody3D] = []


func is_jenner() -> bool:
	return profile_id == "jenner_jr7d"


func upper_height() -> float:
	return 2.10 if is_jenner() else 1.87


func _ready() -> void:
	build()
	stand()


func build() -> void:
	_profile = VoxelChassis.find(profile_id)
	_chassis = Node3D.new()
	_chassis.name = "Frame"
	add_child(_chassis)
	_upper = Node3D.new()
	_upper.name = "UpperBody"
	_upper.position.y = upper_height()
	_chassis.add_child(_upper)
	var rig := VoxelMechRig.build(_chassis, _upper, _profile)
	parts = rig["parts"]
	sockets = rig["sockets"]
	hips = rig["hips"]
	knees = rig["knees"]
	hocks = rig["hocks"]
	ankles = rig["ankles"]
	arms = rig["arms"]


func is_digitigrade() -> bool:
	return VoxelChassis.is_digitigrade(_profile)


func gait_foot(phase: float) -> Vector2:
	if is_jenner():
		return VoxelJennerGait.foot_target(phase)
	return VoxelDigitigradeGait.foot_target(phase) if is_digitigrade() \
			else VoxelGait.foot_target(phase)


func advance_gait(delta: float) -> void:
	if not walking:
		return
	var cycle := VoxelJennerGait.CYCLE_SECONDS if is_jenner() else (VoxelDigitigradeGait.CYCLE_SECONDS if is_digitigrade() else VoxelGait.CYCLE_SECONDS)
	gait_phase = fposmod(gait_phase + delta / cycle, 1.0)
	_pose(gait_phase)
	if travel_remaining > 0.0:
		var speed := VoxelJennerGait.horizontal_speed() if is_jenner() else (VoxelDigitigradeGait.horizontal_speed() if is_digitigrade() \
				else VoxelGait.STRIDE / (VoxelGait.STANCE_FRACTION * VoxelGait.CYCLE_SECONDS))
		var distance := minf(travel_remaining, speed * delta)
		position.z -= distance
		travel_remaining -= distance
		if travel_remaining <= 0.0:
			walking = false
			stand()


func _process(delta: float) -> void:
	advance_gait(delta)


func _pose(phase: float) -> void:
	for side in 2:
		var hip: Node3D = hips[side]
		if hip.get_parent() != _chassis:
			continue
		var p := phase + 0.5 * side
		var knee: Node3D = knees[side]
		var ankle: Node3D = ankles[side]
		if is_digitigrade():
			var angles := VoxelJennerGait.sample(p, hip.position.y) if is_jenner() \
					else VoxelDigitigradeGait.sample(p, hip.position.y)
			hip.rotation.x = angles.x
			if knee.get_parent() == hip:
				knee.rotation.x = angles.y
				var hock: Node3D = hocks[side]
				if hock.get_parent() == knee:
					hock.rotation.x = angles.z
					ankle.rotation.x = angles.w
		else:
			var angles := VoxelGait.sample(p, hip.position.y)
			hip.rotation.x = angles.x
			if knee.get_parent() == hip:
				knee.rotation.x = angles.y
				ankle.rotation.x = angles.z
		var shoulder: Node3D = arms[side]
		if shoulder.get_parent() == _upper:
			var amplitude := 0.018 if is_digitigrade() else 0.040
			shoulder.rotation.x = sin(p * TAU) * amplitude
	_stabilize_upper(phase)


func _stabilize_upper(phase: float) -> void:
	var motion := 1.0 - clampf(upper_stability, 0.0, 1.0)
	_upper.rotation.x = sin(phase * TAU) * 0.060 * motion
	_upper.rotation.z = sin(phase * TAU) * 0.045 * motion
	_upper.position.y = upper_height() + (1.0 - cos(phase * TAU * 2.0)) * 0.025 * motion


func start_walk(distance: float = 3.0) -> void:
	position = Vector3(0, 0, 1.7)
	gait_phase = 0.0
	travel_remaining = distance
	walking = true


func stand() -> void:
	for side in 2:
		var hip: Node3D = hips[side]
		if hip.get_parent() != _chassis:
			continue
		if is_digitigrade():
			# Both Jenner feet remain planted, but their neutral toe positions
			# are staggered so the hock silhouette stays visible in profile.
			var neutral_phase := (0.20 if side == 0 else 0.41) if is_jenner() else 0.29
			var angles := VoxelJennerGait.sample(neutral_phase, hip.position.y) if is_jenner() \
					else VoxelDigitigradeGait.sample(neutral_phase, hip.position.y)
			hip.rotation.x = angles.x
			var knee: Node3D = knees[side]
			if knee.get_parent() == hip:
				knee.rotation.x = angles.y
				var hock: Node3D = hocks[side]
				if hock.get_parent() == knee:
					hock.rotation.x = angles.z
					ankles[side].rotation.x = angles.w
		else:
			hip.rotation.x = 0.25
			var knee: Node3D = knees[side]
			if knee.get_parent() == hip:
				knee.rotation.x = -0.5
				ankles[side].rotation.x = 0.25
		var shoulder: Node3D = arms[side]
		if shoulder.get_parent() == _upper:
			shoulder.rotation.x = 0.0
	_upper.rotation = Vector3.ZERO
	_upper.position.y = upper_height()


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
	if root.get_parent() != _chassis and root.get_parent() != _upper \
			and not hips.has(root.get_parent()) and not knees.has(root.get_parent()):
		return
	var old_transform := root.global_transform
	root.get_parent().remove_child(root)
	var body := RigidBody3D.new()
	body.name = key + "_wreck"
	get_tree().current_scene.add_child(body)
	body.global_transform = old_transform
	body.add_child(root)
	root.transform = Transform3D.IDENTITY
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.60, 0.80, 0.65)
	collision.shape = box
	collision.position.y = -0.25
	body.add_child(collision)
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
