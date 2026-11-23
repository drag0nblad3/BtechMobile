extends TestCase
## Official MegaMek records and published Master Unit List BV for the November 2026 additions.

const IDS := ["solitaire_3", "mauler_mal4r", "hatamoto_chi_htm30t"]
const BV := [1608, 2050, 2196]
const TONNAGE := [25, 90, 80]


func test_official_variants_load_at_record_sheet_weight_and_bv() -> void:
	var db := designs()
	for i in IDS.size():
		var d: UnitDef = db.get_def(IDS[i])
		check(d != null, IDS[i] + " should be in the catalog")
		if d == null:
			continue
		check_eq(d.bv, BV[i], d.id + " uses the official MUL BV")
		check_eq(DesignWeight.total(d), float(TONNAGE[i]), d.id + " exact sourced tonnage")
		check(String(d.source.get("megamek", "")).ends_with(".mtf"), d.id + " MegaMek source")
		check_eq(d.source.get("bv", ""), "mul", d.id + " provenance")
		check(String(d.source.get("mul_url", "")).begins_with("https://masterunitlist.battletech.com/units/"))
		var u := Unit.new(i + 1, d, 0, Vector2i.ZERO, 0)
		check_eq(u.weapons.size(), d.weapon_mounts.size(), d.id + " all weapons mounted")


func test_solitaire_3_preserves_distinct_clan_weapons_and_supercharger() -> void:
	var d: UnitDef = designs().get_def("solitaire_3")
	check(d != null)
	if d == null:
		return
	check_eq(_count(d, "c_improved_heavy_large_laser", Location.RT), 1)
	check_eq(_count(d, "c_er_small_laser", Location.CT), 1)
	check_eq(_count(d, "c_er_small_laser", Location.LT), 1)
	check_eq(_count(d, "c_heavy_small_laser", Location.LT), 1)
	check_eq(d.supercharger_loc, Location.CT)
	check_eq(d.armor_type, "ferro_fibrous")
	check(d.clan_part("engine"))


func test_mauler_4r_mixed_clan_and_is_loadout() -> void:
	var d: UnitDef = designs().get_def("mauler_mal4r")
	check(d != null)
	if d == null:
		return
	check(d.clan_part("heat_sinks"))
	check(not d.clan_part("engine"))
	for loc in [Location.LT, Location.RT]:
		check_eq(_count(d, "light_ac5", loc), 2)
		check_eq(_count(d, "c_lrm15", loc), 1)
	for loc in [Location.LA, Location.RA]:
		check_eq(_count(d, "c_large_pulse_laser", loc), 1)
		check(d.case2_locs.has(loc))
	check_eq(d.ammo_mounts.size(), 8)
	check_eq(d.case2_locs.size(), 4)


func test_hatamoto_30t_keeps_ballistic_armor_and_heavy_ppcs() -> void:
	var d: UnitDef = designs().get_def("hatamoto_chi_htm30t")
	check(d != null)
	if d == null:
		return
	check_eq(d.armor_type, "ballistic_reinforced")
	check_eq(d.gyro_type, "xl")
	check_eq(_count(d, "heavy_ppc", Location.LA), 1)
	check_eq(_count(d, "heavy_ppc", Location.RA), 1)
	check_eq(_count(d, "srm6", Location.LT), 1)
	check_eq(_count(d, "srm6", Location.RT), 1)
	check_eq(d.case2_locs.size(), 2)


func _count(d: UnitDef, id: String, loc: int) -> int:
	var n := 0
	for m: Dictionary in d.weapon_mounts:
		if (m["weapon"] as WeaponDef).id == id and m["loc"] == loc:
			n += 1
	return n
