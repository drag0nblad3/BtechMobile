extends TestCase
## Five new official BattleMech chassis from MegaMek MTF and the MUL.

const IDS := ["hellhound_conjurer", "black_hawk_standard", "dominator",
		"hawkwolf_hwk4f", "koshi_standard"]
const BV := [1813, 2183, 3018, 1428, 760]
const TONS := [50, 50, 65, 80, 25]
const WEAPONS := [5, 6, 4, 4, 4]
const AMMO := [1, 4, 1, 6, 3]


func test_all_official_chassis_and_provenance() -> void:
	var db := designs()
	for i in IDS.size():
		var d: UnitDef = db.get_def(IDS[i])
		check(d != null, IDS[i] + " registered")
		if d == null:
			continue
		check_eq(d.tonnage, TONS[i])
		check_eq(d.bv, BV[i], d.id + " published MUL BV")
		check_eq(DesignWeight.total(d), float(TONS[i]), d.id + " record-sheet construction")
		check_eq(d.weapon_mounts.size(), WEAPONS[i], d.id + " sourced weapons")
		check_eq(d.ammo_mounts.size(), AMMO[i], d.id + " sourced ammunition")
		check_eq(d.source.get("bv", ""), "mul")
		check(int(d.source.get("mul_id", 0)) > 0)
		check(String(d.source.get("megamek", "")).ends_with(".mtf"))
		var u := Unit.new(i + 1, d, 0, Vector2i.ZERO, 0)
		check_eq(u.weapons.size(), WEAPONS[i])
		for w in u.weapons:
			if w.def.uses_ammo():
				check(u.ammo.any(func(a: AmmoBin) -> bool: return a.weapon == w.def),
						d.id + ": missing " + w.def.id + " ammunition")


func test_hellhound_and_black_hawk_are_distinct_non_omni_chassis() -> void:
	var h: UnitDef = designs().get_def("hellhound_conjurer")
	check(not h.omni)
	check_eq(h.jump_mp, 6)
	check_eq(_count(h, "c_large_pulse_laser", Location.RA), 1)
	check_eq(_count(h, "c_streak_srm2", Location.LT), 2)
	var b: UnitDef = designs().get_def("black_hawk_standard")
	check(not b.omni, "Standard Black Hawk is not the Nova OmniMech")
	check_eq(b.jump_mp, 5)
	check_eq(_count(b, "c_streak_srm4", Location.LA), 2)
	check_eq(_count(b, "c_streak_srm4", Location.RA), 2)


func test_dominator_has_rear_laser_computer_and_supercharger() -> void:
	var d: UnitDef = designs().get_def("dominator")
	check_eq(d.supercharger_loc, Location.CT)
	check_eq(d.tc_loc, Location.RT)
	check_eq(d.heat_sinks, 18)
	check_eq(d.jump_mp, 5)
	check_eq(_count(d, "c_er_ppc", Location.RA), 1)
	check(d.weapon_mounts.any(func(m: Dictionary) -> bool:
			return m["loc"] == Location.HD and m["rear"]), "rear-facing head laser")


func test_hawkwolf_and_koshi_support_loadouts() -> void:
	var h: UnitDef = designs().get_def("hawkwolf_hwk4f")
	check(not h.has_actuator(Location.LA, "hand"))
	check(not h.has_actuator(Location.RA, "hand"))
	check_eq(_count(h, "lrm15", Location.LA), 1)
	check_eq(_count(h, "lrm15", Location.RA), 1)
	check_eq(_count(h, "mml5", Location.LT), 1)
	check_eq(_count(h, "mml5", Location.RT), 1)
	check(h.case_locs.has(Location.RT))
	check(h.ammo_mounts.any(func(a: Dictionary) -> bool:
			return a["kind"] == "srm"), "MML SRM ammo is retained")
	var k: UnitDef = designs().get_def("koshi_standard")
	check_eq(k.probe, "c_active_probe")
	check_eq(k.probe_loc, Location.HD)
	check_eq(k.jump_mp, 6)
	check_eq(_count(k, "c_srm4", Location.LA), 2)
	check_eq(_count(k, "c_srm4", Location.RA), 2)
	check(k.inert.any(func(item: Dictionary) -> bool:
			return item["kind"] == "c_light_tag"), "Light TAG equipment is not dropped")


func _count(d: UnitDef, id: String, loc: int) -> int:
	var total := 0
	for mount: Dictionary in d.weapon_mounts:
		if (mount["weapon"] as WeaponDef).id == id and mount["loc"] == loc:
			total += 1
	return total
