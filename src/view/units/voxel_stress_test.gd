class_name VoxelStressTest
extends Node3D
## Real geometry load test: 20 highest-detail chassis and repeated voxel hits.
## Models are constructed one per frame to keep the stop control responsive.
## The CPU/GPU cost is intentionally representative of twenty full models.

signal all_spawned

const TARGET_COUNT := 20
const COLUMNS := 5
const GRID_SPACING := 2.45
const SHOT_INTERVAL := 0.30
const SAMPLE_INTERVAL := 1.0

var profile: Dictionary = {}
var models: Array[VoxelMech] = []
var original_voxels := 0
var voxels_removed := 0
var shots_attempted := 0
var shots_hit := 0
var latest_fps := 0.0
var minimum_fps := INF
var average_fps := 0.0
var elapsed_seconds := 0.0
var _fps_samples := 0
var _fps_sum := 0.0
var _shot_timer := 0.0
var _fps_timer := 0.0
var _rng := RandomNumberGenerator.new()


## Always use counts generated from actual chassis cells, not a fixed model ID.
static func highest_voxel_profile(profiles: Array[Dictionary],
		counts: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var highest := -1
	for entry: Dictionary in profiles:
		var id := str(entry.get("id", ""))
		if not counts.has(id):
			continue
		var count := int(counts[id])
		if count > highest:
			highest = count
			best = entry
	return best


static func grid_position(index: int) -> Vector3:
	var column := index % COLUMNS
	var row := index / COLUMNS
	return Vector3((float(column) - 2.0) * GRID_SPACING, 0.0,
			(float(row) - 1.5) * GRID_SPACING)


func start(chosen_profile: Dictionary, seed: int = -1) -> void:
	assert(profile.is_empty() and not chosen_profile.is_empty())
	profile = chosen_profile.duplicate()
	if seed >= 0:
		_rng.seed = seed
	else:
		_rng.randomize()
	set_process(true)


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if profile.is_empty():
		return
	if models.size() < TARGET_COUNT:
		_spawn_one()
		if models.size() == TARGET_COUNT:
			all_spawned.emit()
		return
	elapsed_seconds += delta
	_fps_timer += delta
	if _fps_timer >= SAMPLE_INTERVAL:
		_fps_timer = fmod(_fps_timer, SAMPLE_INTERVAL)
		var sample := float(Engine.get_frames_per_second())
		if sample > 0.0:
			latest_fps = sample
			minimum_fps = minf(minimum_fps, sample)
			_fps_sum += sample
			_fps_samples += 1
			average_fps = _fps_sum / float(_fps_samples)
	_shot_timer += delta
	if _shot_timer >= SHOT_INTERVAL:
		_shot_timer = fmod(_shot_timer, SHOT_INTERVAL)
		ping_random_model()


func _spawn_one() -> void:
	var index := models.size()
	var mech := VoxelMech.new()
	mech.name = "StressMech_%02d" % index
	mech.profile_id = str(profile["id"])
	mech.detail_level = int(profile.get("voxel_detail", 1))
	mech.upper_stability = 0.98
	mech.position = grid_position(index)
	mech.rotation.y = _rng.randf_range(-0.16, 0.16)
	add_child(mech)
	# These are stationary targets; avoid 20 extra idle _process callbacks.
	mech.set_process(false)
	models.append(mech)
	original_voxels += mech.initial_voxels()


## Select a real surface voxel rather than firing into the center of a solid
## block. A few randomized attempts avoid a costly full-surface enumeration.
static func random_surface_cell(part: VoxelPart,
		rng: RandomNumberGenerator) -> Vector3i:
	var keys := part.cells.keys()
	if keys.is_empty():
		return Vector3i.ZERO
	var chosen: Vector3i = keys[rng.randi_range(0, keys.size() - 1)]
	for attempt in 24:
		var candidate: Vector3i = keys[rng.randi_range(0, keys.size() - 1)]
		for direction: Vector3i in VoxelPart.DIRECTIONS:
			if not part.cells.has(candidate + direction):
				return candidate
	return chosen


func ping_random_model() -> int:
	if models.size() != TARGET_COUNT:
		return 0
	shots_attempted += 1
	var index := _rng.randi_range(0, models.size() - 1)
	var target := models[index]
	var names := target.parts.keys()
	if names.is_empty():
		return 0
	# Select from all parts, including individual shins, feet and weapon pods.
	var key: String = names[_rng.randi_range(0, names.size() - 1)]
	var part: VoxelPart = target.parts[key]
	if part.cells.is_empty() or not part.is_inside_tree():
		return 0
	var cell := random_surface_cell(part, _rng)
	var local_point := (Vector3(cell) + Vector3.ONE * 0.5) * part.voxel_size
	var impact_world := part.to_global(local_point)
	var radius := _rng.randf_range(0.10, 0.19)
	var removed := target.hit_part(key, impact_world, radius)
	if removed > 0:
		shots_hit += 1
		voxels_removed += removed
	return removed


func remaining_voxels() -> int:
	return original_voxels - voxels_removed


func current_fps() -> float:
	return float(Engine.get_frames_per_second())


func min_fps_display() -> float:
	return minimum_fps if _fps_samples > 0 else 0.0
