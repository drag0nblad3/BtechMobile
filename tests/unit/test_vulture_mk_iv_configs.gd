extends TestCase
## Complete canonical Vulture Mk IV OmniMech Prime–E record-sheet validation.

const VARIANTS := ["prime", "a", "b", "c", "d", "e"]
const BV := [2110, 2177, 2649, 2584, 2346, 2151]
const GUNS := [8, 8, 6, 4, 6, 8]
const AMMO := [3, 4, 2, 2, 6, 4]
const SINKS := [12, 12, 12, 13, 14, 12]


func test_all_official_vulture_mk_iv_configs_exist_and_validate() -> void:
	var db := designs()
	for i in VARIANTS.size():
		var id := "vulture_mk_iv_" + VARIANTS[i]
		var d: UnitDef = db.get_def(id)
		check(d != null, id + " loaded from official MegaMek")
		if d == null:
			continue
		check(d.omni)
		check_eq(d.chassis, "vulture_mk_iv")
		check_eq(d.tonnage, 60)
		check_eq(d.walk_mp, 5)
		check_eq(d.bv, BV[i], id + " published MUL BV")
		check_eq(d.heat_sinks, SINKS[i])
		check_eq(d.armor_type, "ferro_lamellor")
		check_eq(DesignWeight.total(d), 60.0, id + " canonical record weight")
		check_eq(d.weapon_mounts.size(), GUNS[i])
		check_eq(d.ammo_mounts.size(), AMMO[i])
		check(String(d.source.get("megamek", "")).ends_with(".mtf"), id + " official loadout source")
		check_eq(d.source.get("bv", ""), "mul", id + " published MUL source")
		var u := Unit.new(i + 1, d, 0, Vector2i.ZERO, 0)
		check_eq(u.weapons.size(), GUNS[i])
		for w in u.weapons:
			if w.def.uses_ammo():
				check(u.ammo.any(func(a: AmmoBin) -> bool: return a.weapon == w.def),
						id + " ammunition available for " + w.def.id)


func test_prime_uses_lb5x_cluster_and_four_srm6() -> void:
	var d: UnitDef = designs().get_def("vulture_mk_iv_prime")
	check_eq(_count(d, "c_lb5x_ac", Location.LA), 1)
	check_eq(_count(d, "c_er_ppc", Location.RA), 1)
	check_eq(_count(d, "c_srm6", Location.LT), 2)
	check_eq(_count(d, "c_srm6", Location.RT), 2)
	check(d.ammo_mounts.any(func(a: Dictionary) -> bool:
			return a["kind"] == "cluster"), "prime has LB-X cluster rounds")


func test_c_and_d_config_systems_and_munitions() -> void:
	var c: UnitDef = designs().get_def("vulture_mk_iv_c")
	check_eq(c.tc_loc, Location.RT)
	check_eq(_count(c, "c_gauss_rifle", Location.LA), 1)
	check_eq(_count(c, "c_improved_heavy_large_laser", Location.RA), 1)
	var d: UnitDef = designs().get_def("vulture_mk_iv_d")
	check_eq(_count(d, "c_atm12", Location.LT), 1)
	check_eq(_count(d, "c_atm12", Location.RT), 1)
	for kind in ["er", "he"]:
		check_eq(d.ammo_mounts.filter(func(a: Dictionary) -> bool:
				return a["kind"] == kind).size(), 2, "two ATM " + kind + " bins")


func _count(d: UnitDef, id: String, loc: int) -> int:
	var n := 0
	for mount: Dictionary in d.weapon_mounts:
		if (mount["weapon"] as WeaponDef).id == id and mount["loc"] == loc:
			n += 1
	return n
