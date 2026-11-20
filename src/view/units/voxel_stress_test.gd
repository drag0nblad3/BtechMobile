class_name VoxelStressTest
extends Node3D
## Render/load stress scenario: 20 independent copies of the densest chassis.
## Spawns one per frame, then continuously damages random exposed surfaces.

const MECH_COUNT := 20
const COLUMNS := 4
const X_SPACING := 3.05
const Z_SPACING := 2.65
const HITS_PER_SECOND := 5.0
const MAX_HITS_PER_FRAME := 2

var profile: Dictionary = {}
var render_surfaces := true  ## CI may disable GPU meshing, never in the live lab.
var models: Array[VoxelMech] = []
var spawning := false
var running := false
var shot_attempts := 0
var successful_hits := 0
var removed_voxels := 0
var original_voxels := 0
var elapsed_seconds := 0.0
var min_fps := 0
var _hit_clock := 0.0
var _fps_warmup := 0.0
var _random := RandomNumberGenerator.new()


func begin(chassis_profile: Dictionary, seed: int = 0) -> void:
	assert(not spawning and not running)
	assert(not chassis_profile.is_empty())
	profile = chassis_profile.duplicate(true)
	_random.seed = seed if seed > 0 else (Time.get_ticks_usec() ^ randi())
	spawning = true
	shot_attempts = 0
	successful_hits = 0
	removed_voxels = 0
	original_voxels = 0
	elapsed_seconds = 0.0
	min_fps = 0
	_hit_clock = 0.0
	_fps_warmup = 0.0


func _process(delta: float) -> void:
	if spawning:
		spawn_next()
		return
	if not running:
		return
	elapsed_seconds += delta
	_fps_warmup += delta
	# Don't include startup/spawn hitches in the running minimum; FPS itself
	# stays live and includes the impact-induced frame drops.
	var fps := Engine.get_frames_per_second()
	if _fps_warmup >= 1.0 and fps > 0:
		min_fps = fps if min_fps == 0 else mini(min_fps, fps)
	_hit_clock += delta
	var interval := 1.0 / HITS_PER_SECOND
	var hits_this_frame := 0
	while _hit_clock >= interval and hits_this_frame < MAX_HITS_PER_FRAME:
		_hit_clock -= interval
		hit_random_mech()
		hits_this_frame += 1
	# Avoid a burst backlog after a long rendering stall.
	_hit_clock = minf(_hit_clock, interval * MAX_HITS_PER_FRAME)


func spawn_next() -> void:
	if not spawning or models.size() >= MECH_COUNT:
		return
	var index := models.size()
	var model := VoxelMech.new()
	model.name = "StressMech%02d" % index
	model.profile_id = str(profile["id"])
	model.detail_level = int(profile.get("voxel_detail", 1))
	model.render_surfaces = render_surfaces
	model.upper_stability = 0.98
	add_child(model)
	model.position = Vector3(
			(float(index % COLUMNS) - 1.5) * X_SPACING,
			0.0,
			(float(index / COLUMNS) - 2.0) * Z_SPACING)
	model.walking = false
	model.set_damage_seed(_random.randi())
	models.append(model)
	original_voxels += model.initial_voxels()
	if models.size() == MECH_COUNT:
		spawning = false
		running = true
		_hit_clock = 0.0


func hit_random_mech() -> int:
	if not running or models.is_empty():
		return 0
	var targets := ["torso", "left_arm", "right_arm", "left_leg",
			"right_leg", "left_leg_shin", "right_leg_shin",
			"left_leg_metatarsal", "right_leg_metatarsal"]
	# Try multiple randomly selected mechs/parts before declaring a miss.
	for attempt in 16:
		var model: VoxelMech = models[_random.randi_range(0, models.size() - 1)]
		var part_name: String = targets[_random.randi_range(0, targets.size() - 1)]
		if not model.parts.has(part_name):
			continue
		var part: VoxelPart = model.parts[part_name]
		if not is_instance_valid(part) or not model.is_ancestor_of(part) \
				or part.cells.is_empty():
			continue
		var point := _surface_hit(part)
		if point.is_empty():
			continue
		shot_attempts += 1
		var removed := model.hit_part(part_name, point["point"],
				_random.randf_range(0.14, 0.25))
		if removed > 0:
			successful_hits += 1
			removed_voxels += removed
		return removed
	shot_attempts += 1
	return 0


## Random rays from outside the exact part bounding box strike exposed cells,
## rather than digging invisible cavities deep inside solid armor.
func _surface_hit(part: VoxelPart) -> Dictionary:
	var box: AABB = part._local_bounds
	if box.size.length_squared() <= 0.0:
		return {}
	for attempt in 12:
		var local := box.position + Vector3(_random.randf(), _random.randf(),
				_random.randf()) * box.size
		var direction := Vector3.ZERO
		var axis := _random.randi_range(0, 2)
		var sign := -1 if _random.randi_range(0, 1) == 0 else 1
		var far := part.voxel_size * 2.0
		match axis:
			0:
				local.x = box.position.x - far if sign > 0 else box.end.x + far
				direction.x = sign
			1:
				local.y = box.position.y - far if sign > 0 else box.end.y + far
				direction.y = sign
			2:
				local.z = box.position.z - far if sign > 0 else box.end.z + far
				direction.z = sign
		var world_origin := part.to_global(local)
		var world_direction := (part.global_transform.basis * direction).normalized()
		var hit := part.pick_ray(world_origin, world_direction)
		if not hit.is_empty():
			return hit
	return {}


func progress_text() -> String:
	var model_name := str(profile.get("name", "Mech"))
	if spawning:
		return "STRESS: building %d / %d %s mechs | FPS %d" % [
				models.size(), MECH_COUNT, model_name, Engine.get_frames_per_second()]
	return "STRESS: %d x %s | FPS %d (low %s) | %.1fs\nHits %d (%d damaging) | %d / %d voxels | %d removed" % [
			models.size(), model_name, Engine.get_frames_per_second(),
			str(min_fps) if min_fps > 0 else "measuring", elapsed_seconds,
			shot_attempts, successful_hits,
			maxi(0, original_voxels - removed_voxels), original_voxels,
			removed_voxels]


func end() -> void:
	spawning = false
	running = false
	for model in models:
		if is_instance_valid(model):
			remove_child(model)
			model.free()
	models.clear()


func _exit_tree() -> void:
	# VoxelMech tears down detached debris in its own _exit_tree.
	if not models.is_empty():
		end()
