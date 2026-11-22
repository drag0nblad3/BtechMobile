extends TestCase
## Special armor and structure (ArmorTypes, StructureTypes, pp. 201-205).


func _unit(armor_type: String, structure_type := "standard") -> Unit:
	var d := UnitDef.from_dict({"id": "t", "name": "t", "tonnage": 50, "walk_mp": 4, "armor_type": armor_type,
			"structure_type": structure_type,
			"armor": {"CT": 10, "LT": 10, "RT": 10, "LA": 10, "RA": 10, "LL": 10, "RL": 10, "HD": 9}}, weapons())
	return Unit.new(1, d, 0, Vector2i.ZERO, 0)


func test_ballistic_reinforced_halves_ballistics_only() -> void:
	var u := _unit("ballistic_reinforced")
	Damage.apply(u, Location.LA, 5, false, ["DB"])
	check_eq(u.armor[Location.LA], 7, "5 ballistic points take 3 pips (odd point takes one)")
	Damage.apply(u, Location.LA, 4, false, ["DE"])
	check_eq(u.armor[Location.LA], 3, "lasers do full damage")


func test_reflective() -> void:
	var u := _unit("reflective")
	Damage.apply(u, Location.LA, 6, false, ["DE"])
	check_eq(u.armor[Location.LA], 7, "6 laser damage takes 3 pips")
	Damage.apply(u, Location.LA, 3, false, ["physical"])
	check_eq(u.armor[Location.LA], 1, "a kick for 3 takes 6 pips")
	var st := u.structure[Location.LA]
	Damage.apply(u, Location.LA, 2, false, ["physical"])
	check_eq(u.armor[Location.LA], 0, "the last pip goes")
	check_eq(st - u.structure[Location.LA], 1, "the rest goes through")


func test_hardened_carries_odd_points() -> void:
	var u := _unit("hardened")
	Damage.apply(u, Location.LA, 3, false, ["DE"])
	check_eq(u.armor[Location.LA], 9, "3 points: 1 pip, 1 carried")
	Damage.apply(u, Location.LA, 1, false, ["DE"])
	check_eq(u.armor[Location.LA], 8, "the carried point completes a pip")
	check_eq(u.run_mp(), 5, "-1 running MP (4 walk -> 5)")
	check(Psr.standing_mods(u).mods.any(func(m: Dictionary) -> bool: return m["label"] == "hardened armor"), "+1 piloting")
	var steps := Damage.apply(u, Location.CT, 2, false, ["DE"])
	check_eq(steps[0]["tac_mod"], -2, "-2 on a TAC roll")


func test_ferro_lamellor_and_ablation() -> void:
	var u := _unit("ferro_lamellor")
	Damage.apply(u, Location.LA, 10, false, ["DB"])
	check_eq(u.armor[Location.LA], 2, "10 damage -> 8")
	var pellet := Damage.apply(u, Location.LA, 1, false, ["DB"])
	check_eq(u.armor[Location.LA], 2, "a 1-point pellet does nothing")
	check(pellet[0]["tac_mod"] == null, "and can't cause a TAC")
	var a := _unit("anti_penetrative")
	check(Damage.apply(a, Location.CT, 5, false, ["DB"])[0]["tac_mod"] == null, "no TAC through ablation armor")


func test_impact_and_heat_dissipating() -> void:
	var u := _unit("impact_resistant")
	Damage.apply(u, Location.LA, 5, false, ["fall"])
	check_eq(u.armor[Location.LA], 8, "falls halved, rounded down")
	Damage.apply(u, Location.LA, 6, false, ["physical"])
	check_eq(u.armor[Location.LA], 4, "a 6-point kick does 4")
	var h := _unit("heat_dissipating")
	Damage.apply(h, Location.LA, 3, false, ArmorTypes.weapon_attack(weapons().get_def("flamer")))
	check_eq(h.armor[Location.LA], 8, "flamer damage halved, rounded up")
	check(ArmorTypes.no_outside_heat(h.def), "no outside heat")


func test_reactive_halves_missiles() -> void:
	var u := _unit("reactive")
	Damage.apply(u, Location.LA, 4, false, ArmorTypes.weapon_attack(weapons().get_def("lrm10")))
	check_eq(u.armor[Location.LA], 8, "4 missile points take 2 pips")


func test_structure_types() -> void:
	var c := _unit("standard", "composite")
	c.armor[Location.LA] = 0
	var s0 := c.structure[Location.LA]
	Damage.apply(c, Location.LA, 2)
	check_eq(s0 - c.structure[Location.LA], 4, "composite: 2 pips a point")
	var r := _unit("standard", "reinforced")
	r.armor[Location.LA] = 0
	var r0 := r.structure[Location.LA]
	Damage.apply(r, Location.LA, 3)
	check_eq(r0 - r.structure[Location.LA], 1, "reinforced: 3 points take 1 pip")
	check_eq(r.structure_partial[Location.LA], 1, "and carry 1")
	check_eq(StructureTypes.weight_mult(r.def), 2.0, "twice the weight")
	check_eq(StructureTypes.weight_mult(_unit("standard", "endo_composite").def), 0.75, "endo-composite 3/4")
