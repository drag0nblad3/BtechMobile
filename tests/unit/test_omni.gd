extends TestCase
## OmniMech configurations (OmniConfig): one chassis file, one design each.


func _file() -> Dictionary:
	return {"id": "test_omni", "name": "Test Omni", "tonnage": 50, "walk_mp": 4,
		"tech_base": "clan", "role": "base role",
		"armor": {"CT": 20, "LT": 16, "RT": 16, "LA": 12, "RA": 12, "LL": 16, "RL": 16, "HD": 9},
		"equipment": {"CT": ["c_er_small_laser"]},
		"configs": [
			{"model": "Prime", "role": "laser boat", "equipment": {"RA": ["c_er_large_laser"], "CT": ["c_er_medium_laser"]}},
			{"model": "A", "heat_sinks": 11, "equipment": {"LA": ["c_lrm10", "ammo:c_lrm10", "heat_sink"]}},
		]}


func test_expand_makes_one_design_per_config() -> void:
	var v := OmniConfig.expand(_file())
	check_eq(v.size(), 2)
	var prime := UnitDef.from_dict(v[0], weapons())
	var a := UnitDef.from_dict(v[1], weapons())
	check_eq(prime.id, "test_omni_prime")
	check_eq(prime.display_name(), "Test Omni Prime")
	check(prime.omni and prime.is_clan())
	check_eq([prime.chassis, prime.config], ["test_omni", "Prime"])
	check_eq(prime.role, "laser boat")
	check_eq(a.role, "base role", "config without a role keeps the chassis one")
	check_eq(a.heat_sinks, 11)
	check_eq(prime.weapon_mounts.map(func(m: Dictionary) -> String: return m["weapon"].id),
			["c_er_small_laser", "c_er_medium_laser", "c_er_large_laser"], "fixed gear first in its location")
	check_eq(a.weapon_mounts.size(), 2)
	check(not _file()["equipment"].has("RA"), "the chassis file is left alone")


func test_plain_designs_pass_through() -> void:
	var d := {"id": "x", "name": "x"}
	check_eq(OmniConfig.expand(d), [d])
	check_eq(OmniConfig.config_id("dire_wolf", "Prime B"), "dire_wolf_prime_b")
