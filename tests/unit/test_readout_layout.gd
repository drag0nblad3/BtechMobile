extends TestCase
## Readout presentation must preserve catalog identity and fit varied aspect ratios.


func test_heading_uses_published_role() -> void:
	var d := make_def(9, 20)
	d.bv = 998
	d.role = "Striker: quick and hard-hitting."
	d.source = {"role": "Striker"}
	var line := TechnicalReadout.design_heading(d)
	check(line.contains("20 t") and line.contains("Striker") and line.contains("998 BV"))
	check(not line.contains("hard-hitting"), "Heading should use the short role")


func test_fit_uses_model_scale_and_viewport_aspect() -> void:
	var extent := Vector3(2, 3, 2)
	var wide := ReadoutModel.fit_size(extent, 2.0)
	var narrow := ReadoutModel.fit_size(extent, 0.5)
	check(narrow > wide, "Narrow view needs additional horizontal clearance")
	check(is_equal_approx(ReadoutModel.fit_size(extent * 2.0, 2.0), wide * 2.0))
	check(wide >= extent.y, "Leave room for the projected body")
