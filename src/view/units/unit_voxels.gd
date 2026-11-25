class_name UnitVoxels
extends RefCounted
## View-only adapter between battle GameEvents and the separate JSON voxel rig.
## This never changes record sheets, rule rolls, or the procedural voxel lab.

const PATH := "res://data/voxels/%s.json"


## A unit-specific render may differ in visible armament from the shared chassis.
## Fall back to the established sprite model for ordinary variants.
static func model_path(def: UnitDef) -> String:
	for stem: String in [def.id, def.sprite]:
		if stem.is_empty():
			continue
		for suffix: String in ["", "_voxel"]:
			var candidate := PATH % (stem + suffix)
			if FileAccess.file_exists(candidate):
				return candidate
	return PATH % def.sprite


static func startup_path(def: UnitDef) -> String:
	if not GameSettings.voxel_mechs or def.is_support():
		return ""
	var path := model_path(def)
	return path if FileAccess.file_exists(path) else ""


static func choose(def: UnitDef, side: int, prepared: Dictionary = {}) -> VxMech:
	var path := startup_path(def)
	if path.is_empty():
		return null
	var model: VxModel = prepared.get("model")
	if model != null and not model.errors.is_empty():
		return null
	var mech := VxMech.from_file(path, false, prepared)
	if not mech.model.errors.is_empty():
		mech.free()
		return null
	mech.set_side(side)
	return mech


static func sync(model: Node3D, unit: Unit) -> bool:
	if not (model is VxMech):
		return false
	var mech := model as VxMech
	mech.show_unit(unit)
	var down := unit.prone or unit.destroyed
	mech.anim.walk(false)
	mech.anim.fallen = down
	mech.body.rotation.x = VxAnim.FALLEN if down else 0.0
	mech.body.position.y = 0.22 if down else 0.0
	return true


static func react(model: Node3D, event: GameEvent) -> void:
	if not (model is VxMech):
		return
	var mech := model as VxMech
	var d: Dictionary = event.data
	match event.type:
		GameEvent.DAMAGE:
			var loc := int(d.get("loc", -1))
			if loc >= 0 and loc < Location.COUNT:
				mech.anim.hit_reaction(loc, bool(d.get("rear", false)), int(d.get("amount", 0)))
		GameEvent.FALL, GameEvent.WENT_PRONE, GameEvent.UNIT_DESTROYED:
			mech.anim.fallen = false
			mech.body.rotation.x = 0.0
			mech.anim.fall()
		GameEvent.STAND:
			mech.anim.fallen = true
			mech.body.rotation.x = VxAnim.FALLEN
			mech.anim.stand_up(bool(d.get("ok", false)))
		GameEvent.SHUTDOWN:
			var off := bool(d.get("shutdown", true))
			mech.create_tween().tween_property(mech.body, "rotation:x",
					-0.15 if off else 0.0, 0.25)


static func fire(view: UnitView, d: Dictionary, target: Vector3) -> bool:
	if not (view._model is VxMech):
		return false
	if d.get("no_ammo", false) or d.get("streak_held", false):
		return false
	var index := int(d.get("weapon_index", -1))
	if index < 0 and d.get("weapon", -1) is int:
		index = int(d["weapon"])
	if index < 0:
		var weapon_id := String(d.get("weapon_id", ""))
		for i in view.unit.def.weapon_mounts.size():
			if view.unit.def.weapon_mounts[i]["weapon"].id == weapon_id:
				index = i
				break
	if index < 0 or index >= view.unit.def.weapon_mounts.size():
		return false
	var loc := int(view.unit.def.weapon_mounts[index]["loc"])
	var mech := view._model as VxMech
	if mech.model.parts_at(loc).is_empty() or not mech.is_attached(mech.part_at(loc)):
		return false
	var style := ShotFx.style(String(d.get("weapon_id", "")))
	var kind := "missile" if style == "missile" else "cannon" if style == "ballistic" else "laser"
	mech.anim.fire([loc], target, kind)
	return true
