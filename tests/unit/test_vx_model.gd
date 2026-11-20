extends TestCase
## Claude's text voxel format, record-sheet damage mapping and leg solve.

const PATH := "res://data/voxels/hunchback.json"


func test_hunchback_loads_with_every_location() -> void:
	var m := VxModel.load_file(PATH)
	check(m.errors.is_empty(), "errors: %s" % ", ".join(m.errors))
	for loc in Location.COUNT:
		check(not m.parts_at(loc).is_empty(), "no part for " + Location.code(loc))
	check(m.cell_count() > 3000 and m.cell_count() < 9000, "voxel budget: %d" % m.cell_count())


func test_mirror_flips_cells_and_location() -> void:
	var m := VxModel.load_file(PATH)
	var la := m.part("la")
	var ra := m.part("ra")
	check_eq(ra["loc"], Location.RA)
	check_eq(ra["cells"].size(), la["cells"].size())
	for c: Vector3i in la["cells"]:
		check(ra["cells"].has(Vector3i(-c.x - 1, c.y, c.z)), "mirror missing %s" % c)
		break
	check(m.part("rt")["cells"].size() > m.part("lt")["cells"].size(), "hunch adds to RT")


func test_bad_data_reports_errors() -> void:
	var m := VxModel.from_dict({"materials": [{"name": "a", "color": "fff"}],
			"parts": [{"name": "x", "loc": "ZZ", "shapes": [{"box": [[0, 0, 0], [1, 1, 1]], "mat": "nope"}]}]})
	check(m.errors.size() >= 3, "expected errors, got %s" % m.errors)


func test_damage_matches_record_sheet() -> void:
	var mech := VxMech.from_file(PATH)
	var u := Unit.new(1, UnitDb.load_dir().get_def("hunchback_hbk4g"), 0, Vector2i.ZERO, 0)
	var full := mech.voxel_count()
	Damage.apply(u, Location.CT, 13)  # half the CT front armor
	mech.show_unit(u)
	var half := full - mech.voxel_count()
	check(half > 0, "CT hit removed nothing")
	check(absi(half - mech.damage.order_size(Location.CT, "a") / 2) <= 1, "half the CT armor voxels gone")
	var again := VxMech.from_file(PATH)
	again.show_unit(u)
	check_eq(again.voxel_count(), mech.voxel_count(), "same sheet, same picture")
	mech.free()
	again.free()


func test_destroyed_arm_drops() -> void:
	var mech := VxMech.from_file(PATH)
	var u := Unit.new(1, UnitDb.load_dir().get_def("hunchback_hbk4g"), 0, Vector2i.ZERO, 0)
	Damage.apply(u, Location.LA, 60)
	mech.show_unit(u)
	check(mech.lost.has(Location.LA), "LA should be lost")
	check(not mech.is_attached(mech.shoulders[0]), "left arm still attached")
	mech.free()


func test_leg_solve_reaches_foot() -> void:
	for i in 10:
		var f := VxGait.foot(i / 10.0, 0.42, 0.12)
		var a := VxGait.solve(f.x, 0.7 - f.y, 0.35, 0.4)
		var got := VxGait.ankle_of(a.x, a.y, 0.35, 0.4)
		check(got.distance_to(Vector2(f.x, 0.7 - f.y)) < 0.01, "ankle off at phase %d" % i)
		check(is_zero_approx(a.x + a.y + a.z), "foot not level")
