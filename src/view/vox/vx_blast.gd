class_name VxBlast
extends RefCounted
## One-shot voxel explosions: a fireball, a soot cloud and tumbling debris
## cubes in a single MultiMesh, animated by vx_blast.gdshader from one
## tweened parameter. The node frees itself when done.

const SHADER := preload("res://src/view/shaders/vx_blast.gdshader")

## Presets: cube counts, cube size, burst speed, seconds.
const KINDS := {
	"impact": {"fire": 6, "smoke": 4, "debris": 4, "cube": 0.06, "speed": 0.9, "time": 0.8},
	"blast": {"fire": 26, "smoke": 14, "debris": 18, "cube": 0.11, "speed": 2.2, "time": 1.6},
	"mech": {"fire": 56, "smoke": 22, "debris": 30, "cube": 0.13, "speed": 3.0, "time": 2.2},
	"dust": {"fire": 0, "smoke": 30, "debris": 24, "cube": 0.14, "speed": 1.6, "time": 2.0,
		"smoke_color": Color(0.36, 0.33, 0.29), "debris_color": Color(0.42, 0.4, 0.37)},
}

static var _box: BoxMesh


## Spawns a blast of `kind` (see KINDS) at a world position under holder.
static func spawn(holder: Node, at: Vector3, kind := "blast", seed := 0) -> MultiMeshInstance3D:
	var p: Dictionary = KINDS[kind]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed if seed != 0 else hash(at)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _cube()
	var parts: Array = []  # [w, count]
	for k: String in ["fire", "smoke", "debris"]:
		parts.append([{"fire": 0.0, "smoke": 0.5, "debris": 1.0}[k], int(p[k])])
	mm.instance_count = int(p["fire"]) + int(p["smoke"]) + int(p["debris"])
	var i := 0
	var s: float = p["cube"]
	for part: Array in parts:
		for n in part[1]:
			var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.1, 1.0), rng.randf_range(-1, 1)).normalized()
			var vel := dir * float(p["speed"]) * rng.randf_range(0.4, 1.0)
			if part[0] == 1.0:
				vel.y += float(p["speed"]) * 0.8
			var size := s * rng.randf_range(0.6, 1.3) * (0.6 if part[0] == 1.0 else 1.0)
			mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * size / 0.1), Vector3.ZERO))
			mm.set_instance_custom_data(i, Color(vel.x, vel.y, vel.z, part[0]))
			i += 1
	var inst := MultiMeshInstance3D.new()
	inst.name = "Blast"
	inst.multimesh = mm
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inst.extra_cull_margin = 4.0  # cubes fly well outside the instances' bounds
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	for key: String in ["smoke_color", "debris_color"]:
		if p.has(key):
			mat.set_shader_parameter(key, p[key])
	inst.material_override = mat
	holder.add_child(inst)
	if inst.is_inside_tree():
		inst.global_position = at
	else:
		inst.position = at
	var tw := inst.create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("t", v), 0.0, 1.0, float(p["time"]))
	tw.tween_callback(inst.queue_free)
	return inst


static func _cube() -> BoxMesh:
	if _box == null:
		_box = BoxMesh.new()
		_box.size = Vector3.ONE * 0.1
	return _box
