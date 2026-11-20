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


## Hit points are drawn from the WHOLE exposed surface of a part, not a
## small hand-picked patch near its center. Bounded ray traversal avoids
## allocating/copying every voxel in a 100k+ cell chassis on each shot.
static func random_surface_hit(part: VoxelPart,
		rng: RandomNumberGenerator) -> Dictionary:
	if part.cells.is_empty():
		return {}
	var bounds: AABB = part._local_bounds
	if bounds.size.length_squared() <= 0.0:
		return {}
	for attempt in 48:
		var origin := bounds.position + Vector3(rng.randf(), rng.randf(),
				rng.randf()) * bounds.size
		var direction := Vector3.ZERO
		var side := rng.randi_range(0, 1)
		var axis := rng.randi_range(0, 2)
		var margin := part.voxel_size * 3.0
		match axis:
			0:
				origin.x = bounds.position.x - margin if side == 0 else bounds.end.x + margin
				direction.x = 1.0 if side == 0 else -1.0
			1:
				origin.y = bounds.position.y - margin if side == 0 else bounds.end.y + margin
				direction.y = 1.0 if side == 0 else -1.0
			2:
				origin.z = bounds.position.z - margin if side == 0 else bounds.end.z + margin
				direction.z = 1.0 if side == 0 else -1.0
		var hit := part.pick_ray(part.to_global(origin),
				(part.global_transform.basis * direction).normalized())
		if not hit.is_empty():
			return hit
	return {}


## Larger armor areas take correspondingly wider damage without erasing the
## entire limb at once. A shoulder can suffer a broad crater; a hock stays
## smaller but still receives a meaningful hit.
static func impact_radius(part: VoxelPart, rng: RandomNumberGenerator) -> float:
	var size: Vector3 = part._local_bounds.size
	var span := maxf(size.x, maxf(size.y, size.z))
	return clampf(span * rng.randf_range(0.23, 0.31), 0.25, 0.49)


func ping_random_model() -> int:
	if models.size() != TARGET_COUNT:
		return 0
	shots_attempted += 1
	# Continue after a detached or completely shredded part. Every successful
	# ping must hit an exposed face, with the origin changing across the part.
	for attempt in 12:
		var index := _rng.randi_range(0, models.size() - 1)
		var target: VoxelMech = models[index]
		var names := target.parts.keys()
		if names.is_empty():
			continue
		var key: String = names[_rng.randi_range(0, names.size() - 1)]
		var part: VoxelPart = target.parts[key]
		if not is_instance_valid(part) or not part.is_inside_tree() \
				or part.cells.is_empty():
			continue
		var hit := random_surface_hit(part, _rng)
		if hit.is_empty():
			continue
		var removed := target.hit_part(key, hit["point"], impact_radius(part, _rng))
		if removed > 0:
			shots_hit += 1
			voxels_removed += removed
		return removed
	return 0

func remaining_voxels() -> int:
	return original_voxels - voxels_removed


func current_fps() -> float:
	return float(Engine.get_frames_per_second())


func min_fps_display() -> float:
	return minimum_fps if _fps_samples > 0 else 0.0
