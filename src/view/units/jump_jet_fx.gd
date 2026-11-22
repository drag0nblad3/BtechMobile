class_name JumpJetFx
extends RefCounted
## Cosmetic, bounded thrust plumes on a jumping unit. Four mesh instances,
## no GPU particles, physics objects, shadow maps, or per-frame allocations.

const MAX_ACTIVE := 12
const MESHES_PER_JUMP := 4


static func arc(a: Vector3, b: Vector3, fraction: float, apex: float) -> Vector3:
	var t := clampf(fraction, 0.0, 1.0)
	return a.lerp(b, t) + Vector3(0, sin(t * PI) * apex, 0)


static func spawn(view: UnitView) -> Node3D:
	if view.get_tree().get_nodes_in_group("jump_fx").size() >= MAX_ACTIVE:
		return null
	var plume := Node3D.new()
	plume.name = "JumpPlumes"
	plume.add_to_group("jump_fx")
	view.add_child(plume)
	var tons := float(view.unit.def.tonnage)
	var width := clampf(0.17 + tons / 1200.0, 0.18, 0.27)
	var back := 0.20
	for side in [-1, 1]:
		var x := float(side) * width
		_add_cone(plume, Vector3(x, 0.22, back), 0.68, 0.075, Color("#4cb2e4"), 0.78)
		_add_cone(plume, Vector3(x, 0.32, back), 0.38, 0.036, Color("#ffe4ad"), 0.90)
	return plume


static func _add_cone(parent: Node3D, at: Vector3, length: float, radius: float,
		color: Color, alpha: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = 0.007
	mesh.height = length
	mesh.radial_segments = 8
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.35
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position = at - Vector3(0, length * 0.5, 0)
	parent.add_child(instance)


static func animate(plume: Node3D, fraction: float) -> void:
	if plume == null or not is_instance_valid(plume):
		return
	var t := clampf(fraction, 0.0, 1.0)
	# Full thrust during the rise, reduced toward touchdown. Alternate
	# plume lengths to give an active exhaust appearance without particles.
	var power := 0.25 + 0.75 * sin(PI * (0.10 + t * 0.85))
	var flicker := 0.92 + 0.08 * sin(t * TAU * 11.0)
	plume.scale.y = maxf(0.05, power * flicker)
	for part in plume.get_children():
		if part is MeshInstance3D:
			(part as MeshInstance3D).transparency = 0.10 + t * 0.40
