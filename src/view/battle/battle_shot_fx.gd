class_name BattleShotFx
extends RefCounted
## Cosmetic laser / particle tracks. No rule changes and no persistent lights.
## Uses 1-2 short-lived low-poly cylinders per firing event.

const MAX_ACTIVE := 30
const COLORS := {
	"laser": Color("#ff554a"),
	"ppc": Color("#6edafb"),
	"missile": Color("#ffd78b"),
	"ballistic": Color("#ffd3a0"),
	"flame": Color("#ff843c"),
}


static func style_for(weapon_id: String) -> String:
	var key := weapon_id.to_lower()
	if "ppc" in key:
		return "ppc"
	if "laser" in key:
		return "laser"
	if "flamer" in key or "plasma" in key:
		return "flame"
	if "lrm" in key or "srm" in key or "atm" in key or "mrm" in key 			or "missile" in key or "rocket" in key:
		return "missile"
	return "ballistic"


## Misses land visibly to one side of the target rather than inside its model.
static func destination(start: Vector3, target: Vector3, hit: bool, seed: int) -> Vector3:
	if hit:
		return target
	var across := (target - start).cross(Vector3.UP).normalized()
	if across.length_squared() < 0.01:
		across = Vector3.RIGHT
	var sign_ := -1.0 if (seed & 1) == 0 else 1.0
	return target + across * 0.55 * sign_ + Vector3(0.0, 0.35, 0.0)


static func spawn(holder: Node3D, start: Vector3, target: Vector3,
		weapon_id: String, hit: bool, seed: int = 0) -> void:
	if not start.is_finite() or not target.is_finite() 			or holder.get_child_count() >= MAX_ACTIVE:
		return
	var end := destination(start, target, hit, seed)
	var travel := end - start
	var dist := travel.length()
	if dist < 0.12:
		return
	var kind := style_for(weapon_id)
	var energy := kind in ["laser", "ppc", "flame"]
	var color: Color = COLORS[kind]
	var size := 0.035 if energy else 0.055
	if kind == "ppc":
		size = 0.065
	var duration := 0.22 if energy else 0.26
	var shot := Node3D.new()
	shot.name = "ShotTrail"
	holder.add_child(shot)
	var core := _cylinder(color, size, 1.0)
	shot.add_child(core)
	var axis := travel / dist
	core.quaternion = Quaternion(Vector3.UP, axis)
	if energy:
		core.position = (start + end) * 0.5
		core.scale = Vector3(1.0, dist, 1.0)
		# A transparent halo gives bright beams a soft edge without bloom.
		var halo := _cylinder(Color(color.r, color.g, color.b, 0.23),
				size * 2.5, 0.23)
		shot.add_child(halo)
		halo.quaternion = core.quaternion
		halo.position = core.position
		halo.scale = core.scale
		var fade := shot.create_tween().set_parallel(true)
		fade.tween_property(core, "transparency", 1.0, duration)
		fade.tween_property(halo, "transparency", 1.0, duration)
	else:
		# Ballistic and missile flashes move across the battlefield.
		core.position = start
		core.scale = Vector3(1.0, minf(0.65, dist), 1.0)
		var flight := shot.create_tween().set_parallel(true)
		flight.tween_property(core, "position", end, duration) 				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		flight.tween_property(core, "transparency", 1.0, duration)
	var life := shot.create_tween()
	life.tween_interval(duration + 0.02)
	life.tween_callback(shot.queue_free)


static func _cylinder(color: Color, radius: float, alpha: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 1.0
	mesh.radial_segments = 6
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = 1.0
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst
