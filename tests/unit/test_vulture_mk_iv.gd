extends TestCase
## Canonical Mad Dog Mk IV E (not the older Mad Dog/Vulture Omni chassis).


func test_vulture_mk_iv_e_official_record_sheet() -> void:
	var d: UnitDef = designs().get_def("vulture_mk_iv_e")
	check(d != null, "new Omni chassis must be in the force catalog")
	if d == null:
		return
	check_eq(d.name, "Vulture Mk IV (Mad Dog Mk IV)")
	check_eq(d.model, "E")
	check_eq(d.chassis, "vulture_mk_iv")
	check_eq(d.config, "E")
	check(d.omni)
	check_eq(d.tonnage, 60)
	check_eq(d.walk_mp, 5)
	check_eq(d.bv, 2151, "official MUL BV")
	check_eq(DesignWeight.total(d), 60.0, "canonical component tonnage")
	check_eq(d.armor_type, "ferro_lamellor")
	check_eq(d.heat_sinks, 12)
	check_eq(d.ecm_loc, Location.RT)
	check_eq(d.probe_loc, Location.LT)
	check_eq(d.probe, "c_light_active_probe")
	check_eq(d.weapon_mounts.size(), 8)
	check_eq(_count(d, "c_proto_ac8", Location.LA), 1)
	check_eq(_count(d, "c_improved_heavy_medium_laser", Location.RA), 1)
	check_eq(_count(d, "c_streak_srm6", Location.LT), 2)
	check_eq(_count(d, "c_streak_srm6", Location.RT), 2)
	check_eq(_count(d, "c_er_small_laser", Location.CT), 2)
	check_eq(d.ammo_mounts.size(), 4, "two PAC bins and one Streak bin per torso")
	check(not d.has_actuator(Location.LA, "hand"))
	check(not d.has_actuator(Location.RA, "hand"))
	var u := Unit.new(1, d, 0, Vector2i.ZERO, 0)
	check_eq(u.weapons.size(), 8)
	for w in u.weapons:
		if w.def.uses_ammo():
			check(u.ammo.any(func(a: AmmoBin) -> bool: return a.weapon == w.def),
					"all ammunition-dependent racks have loaded bins")


func _count(d: UnitDef, id: String, loc: int) -> int:
	var n := 0
	for m: Dictionary in d.weapon_mounts:
		if (m["weapon"] as WeaponDef).id == id and m["loc"] == loc:
			n += 1
	return n
