extends TestCase
## Inner Sphere light/heavy MGs, light ACs, ER and heavy flamers, Magshot, Enhanced LRMs (pp. 183-186, 248-249).


func test_table_stats() -> void:
	var db := weapons()
	check_eq(db.get_def("light_ac5").long_range, 15, "LAC/5 long 15")
	check_eq(db.get_def("heavy_machine_gun").damage, 3, "HMG 3 damage")
	check_eq(db.get_def("er_flamer").heat_points, 1, "ER flamer adds 1 heat")
	check_eq(db.get_def("nlrm10").min_range, 3, "NLRM minimum range 3")
	check(db.get_def("magshot").explodes and not db.get_def("magshot").ammo_explodes, "Magshot is a Gauss rifle")


func test_heavy_flamer_ammo_explodes_at_five_a_shot() -> void:
	var bin := AmmoBin.new(weapons().get_def("heavy_flamer"), 0)
	check_eq(bin.shots, 10, "10 shots a ton")
	check_eq(bin.explosion_damage(), 50, "5 per shot remaining")
