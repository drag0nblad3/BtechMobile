extends TestCase
## Non-authoritative impact placement and disabled camera shake.


func test_fallback_mech_impacts_follow_record_sheet_locations() -> void:
	var view := UnitView.new()
	var def := designs().get_def("hunchback_hbk4g")
	view.set_model(PlaceholderMech.build(def, 0))
	var head := view.impact_location(Location.HEAD, false)
	var leg := view.impact_location(Location.LL, false)
	var arm := view.impact_location(Location.RA, false)
	check(head.y > leg.y, "head hit appears above leg hit")
	check(arm.x > 0.0, "RA hit appears on right side")
	var front := view.impact_location(Location.CT, false)
	var rear := view.impact_location(Location.CT, true)
	check(rear.z > front.z, "rear armor hits appear behind front armor")
	view.free()


func test_shake_is_bounded_and_setting_can_disable_it() -> void:
	var rig := CameraRig.new()
	rig.shake(5.0, 42)
	check(rig._shake_strength <= 0.5, "camera kick clamped")
	check_eq(rig._shake_seed, 42)
	rig.free()


func test_smoke_emitter_has_fixed_visual_seed() -> void:
	var smoke := BattleSmoke.new()
	var emitter := smoke._emitter(Color.GRAY, 8, 0.12)
	check(emitter.use_fixed_seed, "visual particle seed remains independent of Dice")
	check_eq(emitter.amount, 8)
	emitter.free()
	smoke.free()
