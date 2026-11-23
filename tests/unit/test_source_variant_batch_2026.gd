extends TestCase
## Six source-verified variants complete the first 20 official designs.

const IDS := ["hellhound_conjurer_7", "koshi_standard_2",
		"koshi_standard_3", "black_hawk_standard_2",
		"black_hawk_standard_3", "dominator_2"]
const BV := [1845, 948, 777, 2161, 2317, 2906]
const TONS := [50, 25, 25, 50, 50, 65]
const GUNS := [5, 2, 6, 4, 6, 5]
const AMMO := [1, 2, 0, 4, 0, 2]


func test_source_variants_and_published_bv() -> void:
	var db := designs()
	for i in IDS.size():
		var d: UnitDef = db.get_def(IDS[i])
		check(d != null, IDS[i] + " exists")
		if d == null:
			continue
		check_eq(d.bv, BV[i], d.id + " published MUL BV")
		check_eq(DesignWeight.total(d), float(TONS[i]), d.id + " sourced construction weight")
		check_eq(d.weapon_mounts.size(), GUNS[i], d.id + " exact weapon count")
		check_eq(d.ammo_mounts.size(), AMMO[i], d.id + " exact ammo bins")
		check_eq(d.source.get("bv", ""), "mul", d.id + " source provenance")
		check(int(d.source.get("mul_id", 0)) > 0, d.id + " official MUL identity")
		check(String(d.source.get("megamek", "")).ends_with(".mtf"), d.id + " MTF")
		var u := Unit.new(i + 1, d, 0, Vector2i.ZERO, 0)
		check_eq(u.weapons.size(), GUNS[i], d.id + " live weapon mounts")


func test_conjurer_7_lrm_racks_replace_streaks() -> void:
	var d: UnitDef = designs().get_def("hellhound_conjurer_7")
	check_eq(_count(d, "c_lrm5", Location.LT), 2)
	check_eq(_count(d, "c_streak_srm2", Location.LT), 0)
	check_eq(d.jump_mp, 6)


func test_koshi_2_and_3_keep_distinct_gear() -> void:
	var k2: UnitDef = designs().get_def("koshi_standard_2")
	check_eq(k2.probe, "", "Koshi 2 has no active probe")
	check_eq(_count(k2, "c_streak_srm6", Location.LA), 1)
	check_eq(_count(k2, "c_streak_srm6", Location.RA), 1)
	var k3: UnitDef = designs().get_def("koshi_standard_3")
	check_eq(k3.heat_sinks, 11)
	check_eq(k3.tc_loc, Location.CT)
	check_eq(k3.masc_loc, Location.CT)
	check_eq(k3.ecm_loc, Location.LT)
	check_eq(k3.probe, "c_active_probe")
	check_eq(k3.probe_loc, Location.HD)
	check_eq(_count(k3, "c_heavy_small_laser", Location.LA), 3)
	check_eq(_count(k3, "c_heavy_small_laser", Location.RA), 3)


func test_black_hawk_2_and_3_have_distinct_armor_and_sinks() -> void:
	var b2: UnitDef = designs().get_def("black_hawk_standard_2")
	check_eq(b2.total_armor(), 152, "ATM version has additional armor")
	check_eq(_count(b2, "c_atm6", Location.LA), 1)
	check_eq(_count(b2, "c_atm6", Location.RA), 1)
	check(b2.ammo_mounts.any(func(a: Dictionary) -> bool: return a["kind"] == "er"))
	check(b2.ammo_mounts.any(func(a: Dictionary) -> bool: return a["kind"] == "he"))
	var b3: UnitDef = designs().get_def("black_hawk_standard_3")
	check_eq(b3.heat_sinks, 22)
	check_eq(_count(b3, "c_er_medium_laser", Location.LA), 2)
	check_eq(_count(b3, "c_er_medium_laser", Location.RA), 2)


func test_dominator_2_uses_artemis_v_not_supercharger() -> void:
	var d: UnitDef = designs().get_def("dominator_2")
	check_eq(d.supercharger_loc, -1)
	check_eq(d.tc_loc, Location.RT)
	check_eq(d.heat_sinks, 17)
	check_eq(_count(d, "c_lrm20", Location.LT), 1)
	check(d.weapon_mounts.any(func(m: Dictionary) -> bool:
			return (m["weapon"] as WeaponDef).id == "c_lrm20" and m["artemis_v"]))
	check_eq(d.ammo_mounts.filter(func(a: Dictionary) -> bool:
			return a["kind"] == "artemis_v").size(), 2)
	check(d.weapon_mounts.any(func(m: Dictionary) -> bool:
			return m["loc"] == Location.HD and m["rear"]), "rear-facing head laser")


func _count(d: UnitDef, id: String, loc: int) -> int:
	var count := 0
	for m: Dictionary in d.weapon_mounts:
		if (m["weapon"] as WeaponDef).id == id and m["loc"] == loc:
			count += 1
	return count
