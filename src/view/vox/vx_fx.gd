class_name VxFx
extends RefCounted
## Short-lived weapon effects: muzzle flash, laser beam, cannon shell,
## impact flash and smoke. Every node frees itself.

const LASER := Color(1.0, 0.25, 0.2)
const FLASH := Color(1.0, 0.82, 0.45)
const SMOKE := Color(0.25, 0.24, 0.23, 0.7)


static func shot(holder: Node, from: Vector3, to: Vector3, laser: bool) -> void:
	flash(holder, from, 0.08 if laser else 0.16)
	if laser:
		_beam(holder, from, to)
		impact(holder, to, false)
		return
	var shell := ball(holder, from, 0.05, FLASH)
	var tw := shell.create_tween()
	tw.tween_property(shell, "global_position", to, maxf(0.08, from.distance_to(to) / 40.0))
	tw.tween_callback(func(): impact(holder, to, true))
	tw.tween_callback(shell.queue_free)


static func impact(holder: Node, at: Vector3, big: bool) -> void:
	flash(holder, at, 0.2 if big else 0.1)
	var puff := ball(holder, at, 0.1, SMOKE)
	var tw := puff.create_tween().set_parallel()
	tw.tween_property(puff, "scale", Vector3.ONE * (4.0 if big else 2.5), 1.2)
	tw.tween_property(puff, "position:y", at.y + 0.4, 1.2)
	tw.tween_property(puff.material_override, "albedo_color:a", 0.0, 1.2)
	tw.chain().tween_callback(puff.queue_free)


static func flash(holder: Node, at: Vector3, radius: float) -> void:
	var f := ball(holder, at, radius, FLASH)
	var tw := f.create_tween()
	tw.tween_property(f, "scale", Vector3.ONE * 0.1, 0.18)
	tw.tween_callback(f.queue_free)


static func _beam(holder: Node, from: Vector3, to: Vector3) -> void:
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.025
	c.bottom_radius = 0.025
	c.height = from.distance_to(to)
	c.radial_segments = 6
	m.mesh = c
	m.material_override = glow(LASER)
	holder.add_child(m)
	m.global_position = (from + to) * 0.5
	var dir := (to - from).normalized()
	var side := dir.cross(Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT).normalized()
	m.global_basis = Basis(side, dir, side.cross(dir))
	var tw := m.create_tween()
	tw.tween_property(m.material_override, "albedo_color:a", 0.0, 0.3)
	tw.tween_callback(m.queue_free)


static func ball(holder: Node, at: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 8
	s.rings = 4
	m.mesh = s
	m.material_override = glow(color)
	holder.add_child(m)
	m.global_position = at
	return m


static func glow(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	return mat
