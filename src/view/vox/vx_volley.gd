class_name VxVolley
extends RefCounted
## Fires a weapon group from a VxMech: lasers from every muzzle, a cannon
## shell with recoil, or a missile salvo rippling out of the launch tubes.

const MISSILES := 15  ## Catapult's LRM-15 reference count; other racks vary.


static func fire(anim: Node, m: VxMech, locs: Array[int], target: Vector3, kind: String) -> void:
	var holder := m.get_parent() if m.get_parent() else m
	var delay := 0.0
	for loc in locs:
		if not m.is_attached(m.part_at(loc)):
			continue
		var points := m.muzzles(loc)
		if kind == "missile":
			for i in points.size():
				var off := Vector3(sin(i * 2.4), 0.0, cos(i * 1.7)) * 0.35
				VxTrails.missile(holder, points[i % points.size()], target + off, delay + i * 0.045)
			delay += 0.2
		else:
			for p in points:
				_later(anim, delay, VxFx.shot.bind(holder, p, target, kind == "laser"))
				delay += 0.07
			if kind == "cannon":
				_recoil(anim, m.pivots[m.model.parts_at(loc)[0]["name"]])


static func _later(anim: Node, delay: float, call: Callable) -> void:
	if delay <= 0.0:
		call.call()
	else:
		anim.get_tree().create_timer(delay).timeout.connect(call)


static func _recoil(anim: Node, joint: Node3D) -> void:
	var rest := joint.position
	var tw := anim.create_tween()
	tw.tween_property(joint, "position", rest + Vector3(0, 0, 0.2), 0.04)
	tw.tween_property(joint, "position", rest, 0.35).set_trans(Tween.TRANS_ELASTIC)
