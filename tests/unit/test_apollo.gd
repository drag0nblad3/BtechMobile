extends TestCase
## Apollo MRM fire control (Apollo, p. 197): no -1 on the Cluster Hits roll.


func _mrm(apollo: bool) -> MountedWeapon:
	var w := MountedWeapon.new(weapons().get_def("mrm10"), Location.RA, false)
	w.apollo = apollo
	return w


func test_apollo_cancels_mrm_penalty() -> void:
	var d := weapons().get_def("mrm10")
	check_eq(Apollo.cluster_mod(_mrm(false), d), -1, "plain MRM -1")
	check_eq(Apollo.cluster_mod(_mrm(true), d), 0, "Apollo removes it")
	var w := _mrm(true)
	w.apollo_lost = true
	check_eq(Apollo.cluster_mod(w, d), -1, "a destroyed Apollo doesn't")


func test_cluster_roll_uses_apollo() -> void:
	var dice := LoadedDice.new()
	dice.queue_2d6(7)
	var res := WeaponModes.cluster(_mrm(true), 1, dice)
	check_eq(int(res["bonus"]), 0, "no modifier with Apollo")
	dice.queue_2d6(7)
	check_eq(int(WeaponModes.cluster(_mrm(false), 1, dice)["bonus"]), -1, "-1 without")


func test_design_item_slot_and_weight() -> void:
	var def := make_def(4, 50)
	DesignItems.add(def, Location.RA, "mrm10+apollo", weapons())
	check(def.weapon_mounts[0]["apollo"], "mount linked")
	var names := (CritLayout.build(def)[Location.RA] as Array).map(func(sl: CritSlot) -> String: return sl.name)
	check(names.has("Apollo FCS"), "Apollo takes a slot: %s" % [names])
	check_eq(float(DesignWeight.breakdown(def)["weapons"]), weapons().get_def("mrm10").tons + 1.0, "1 t")
	var u := Unit.new(1, def, 0, Vector2i.ZERO, 0)
	check(u.weapons[0].apollo, "the live weapon has it")
