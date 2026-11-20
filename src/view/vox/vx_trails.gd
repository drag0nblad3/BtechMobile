class_name VxTrails
extends RefCounted
## Longer-lived effects: arcing missiles with smoke trails, jump jet
## flames, smoke wisps from damaged parts and armor chips knocked loose.
## Counts are kept small for phones.

const FLAME := Color(1.0, 0.55, 0.15, 0.85)
const CHIP_COUNT := 6


static func missile(holder: Node, from: Vector3, to: Vector3, delay: float) -> void:
	var body := VxFx.ball(holder, from, 0.025, Color(0.95, 0.9, 0.8))
	body.visible = false
	var dist := from.distance_to(to)
	var lift := Vector3.UP * dist * 0.35
	var trail := [0]
	var tw := body.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func(): body.visible = true)
	tw.tween_method(func(t: float):
			var a := from.lerp(from + lift, t)
			var b := (from + lift).lerp(to, t)
			body.global_position = a.lerp(b, t)
			trail[0] += 1
			if trail[0] % 3 == 0:
				_puff(holder, body.global_position, 0.03, 0.5), 0.0, 1.0, maxf(0.35, dist / 9.0))
	tw.tween_callback(func(): VxFx.impact(holder, to, false))
	tw.tween_callback(body.queue_free)


static func jet_flame(part: Node3D, at_world: Vector3) -> Node3D:
	var pivot := Node3D.new()
	part.add_child(pivot)
	pivot.global_position = at_world
	pivot.rotation.x = -0.6  # angled down and back
	var cone := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.09
	c.bottom_radius = 0.0
	c.height = 0.75
	c.radial_segments = 8
	cone.mesh = c
	cone.material_override = VxFx.glow(FLAME)
	cone.position.y = -0.37
	pivot.add_child(cone)
	return pivot


## One rising smoke puff; `amount` 0..1 makes it bigger and darker.
static func wisp(holder: Node, at: Vector3, amount: float) -> void:
	var jitter := Vector3(randf_range(-0.08, 0.08), 0.05, randf_range(-0.08, 0.08))
	_puff(holder, at + jitter, 0.04 + 0.05 * amount, 1.6, 0.25 + 0.35 * amount)


static func chips(holder: Node, at: Vector3, color: Color) -> void:
	for i in CHIP_COUNT:
		var chip := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 0.035
		chip.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		chip.material_override = mat
		holder.add_child(chip)
		chip.global_position = at
		var v := Vector3(randf_range(-1, 1), randf_range(0.8, 2.0), randf_range(-1, 1))
		var tw := chip.create_tween()
		tw.tween_method(func(t: float):
				chip.global_position = at + v * t * 0.5 + Vector3.DOWN * 2.5 * t * t
				chip.rotation = Vector3(t * 9.0, t * 7.0, 0), 0.0, 0.7, 0.7)
		tw.tween_callback(chip.queue_free)


static func _puff(holder: Node, at: Vector3, radius: float, life: float, alpha: float = 0.5) -> void:
	var p := VxFx.ball(holder, at, radius, Color(0.3, 0.29, 0.28, alpha))
	var tw := p.create_tween().set_parallel()
	tw.tween_property(p, "scale", Vector3.ONE * 3.0, life)
	tw.tween_property(p, "global_position:y", at.y + 0.5 * life, life)
	tw.tween_property(p.material_override, "albedo_color:a", 0.0, life)
	tw.chain().tween_callback(p.queue_free)
