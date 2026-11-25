class_name MeleeContact
extends RefCounted
## Aim the striking limb at the resolved contact. The lunge is cosmetic,
## never moves the Unit or its hex. Existing rigs remain the visual source.
static func play(v: UnitView, d: Dictionary, contact: Vector3) -> void:
	if not v._model is VxMech:
		return
	var m := v._model as VxMech
	if m.anim.fallen:
		return
	var kind := String(d.get("kind", ""))
	var limb := int(d.get("limb", Location.LA))
	var side := 0 if limb in [Location.LA, Location.LL] else 1
	if kind in ["kick", "dfa"]:
		m.anim.kick(side)
	elif kind in ["punch", "hatchet", "sword", "club", "push", "zweihander"]:
		var joint := m.shoulders[side]
		if m.is_attached(joint):
			var local := joint.get_parent() as Node3D
			var aim := local.to_local(contact) - joint.position
			var pitch := clampf(atan2(-aim.z, -aim.y), -1.8, 2.5)
			var rest := joint.rotation.x
			m.anim.arm_busy[side] = true
			var tw := joint.create_tween()
			tw.tween_property(joint, "rotation:x", rest - 0.6, 0.10)
			tw.tween_property(joint, "rotation:x", pitch, 0.14)
			tw.tween_interval(0.05)
			tw.tween_property(joint, "rotation:x", rest, 0.22)
			tw.tween_callback(func(): m.anim.arm_busy[side] = false)
	var body := m.body
	var original := body.position
	var delta := v.to_local(contact) - body.position
	delta.y = 0.0
	var reach := minf(0.55, delta.length() * 0.2)
	var motion := body.create_tween()
	motion.tween_property(body, "position", original + delta.normalized() * reach, 0.24)
	motion.tween_property(body, "position", original, 0.26)
