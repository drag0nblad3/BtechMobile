extends TestCase
## Verify impact/muzzle separation is grounded in record-sheet locations.


func test_mounts_reflect_anatomy() -> void:
	var left := UnitView.anchor_offset(Location.LA)
	var right := UnitView.anchor_offset(Location.RA)
	check(left.x < 0.0 and right.x > 0.0, "arm weapons use opposite shoulders")
	check(UnitView.anchor_offset(Location.HEAD).y > UnitView.anchor_offset(Location.CT).y,
		"head mounts sit above torso")
	check(UnitView.anchor_offset(Location.LL).y < UnitView.anchor_offset(Location.LT).y,
		"leg impacts are below torso")
	check(UnitView.anchor_offset(Location.CT, true).z > 0.0,
		"rear-mounted guns and damage use the back face")


func test_effect_presets_bounded() -> void:
	check(VxBlast.KINDS.has("armor"), "armor hit spark fragments exist")
	check(VxBlast.KINDS.has("muzzle"), "short muzzle flashes exist")
	check(int(VxBlast.KINDS["muzzle"]["fire"]) <= 8, "no heavy muzzle particles")
