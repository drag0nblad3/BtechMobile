extends TestCase
## Clan Artemis V: exact two-slot fire control, guided ammo and direct-fire bonuses.


func _battle() -> Array:
	var s := GameState.new(open_map(12, 3))
	var d := UnitDef.from_dict({"id": "test_artemis_v", "name": "Test",
			"tonnage": 60, "walk_mp": 4, "tech_base": "clan",
			"armor": {"CT": 20, "RT": 20},
			"equipment": {"RT": ["c_lrm10+artemis_v", "ammo:c_lrm10:artemis_v"]}}, weapons())
	var a := Unit.new(1, d, 0, hex_at(0, 1), 2)
	var t := Unit.new(2, make_def(4), 1, hex_at(5, 1), 5)
	for loc in Location.COUNT:
		t.armor[loc] = 99
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func test_guided_ammo_weight_critical_slots_and_modes() -> void:
	var v := _battle()
	var a: Unit = v[1]
	var w: MountedWeapon = a.weapons[0]
	check(w.artemis_v)
	check_eq(WeaponModes.ammo_kind(w), "artemis_v")
	check_eq(WeaponModes.artemis_bonus(w), 3)
	check(a.can_fire(w), "guided ammunition is available")
	check_eq(a.ammo[0].kind, "artemis_v")
	check_eq(DesignWeight.breakdown(a.def)["weapons"], w.def.tons + 1.5)
	var fcs := a.slots[Location.RT].filter(func(slot: CritSlot) -> bool:
		return slot.kind == CritSlot.Kind.ARTEMIS)
	check_eq(fcs.size(), 2, "Artemis V occupies two critical slots")
	check(BattleFields.names(w).has("artemis_v"), "battle saves preserve Artemis V linkage")


func test_direct_shot_uses_three_cluster_and_accuracy_bonus() -> void:
	var v := _battle()
	var a: Unit = v[1]
	var t: Unit = v[2]
	var w: MountedWeapon = a.weapons[0]
	var th := ToHitCalc.weapon(v[0], a, w, t)
	check(th.possible())
	check(th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "Artemis V"),
			"direct fire receives -1 to-hit bonus")
	var before := a.ammo_for(w.def, "artemis_v")
	var events := []
	var dice := LoadedDice.new()
	dice.queue_2d6(12)  # Hits.
	dice.queue_2d6(6)   # Cluster roll becomes 9 with Artemis V.
	var emit := func(ty: StringName, e: Dictionary) -> void:
		events.append([ty, e])
	WeaponFire.resolve(v[0], dice, emit, a, w, t, th)
	var fired: Dictionary = events.filter(func(e: Array) -> bool:
		return e[0] == GameEvent.WEAPON_FIRED)[0][1]
	check_eq(fired["cluster_bonus"], 3)
	check_eq(fired["missiles"], ClusterTable.hits(10, 9))
	check_eq(a.ammo_for(w.def, "artemis_v"), before - 1)


func test_destroyed_guidance_keeps_ammo_but_loses_bonuses() -> void:
	var v := _battle()
	var a: Unit = v[1]
	var t: Unit = v[2]
	var w: MountedWeapon = a.weapons[0]
	var fcs: Array = a.slots[Location.RT].filter(func(slot: CritSlot) -> bool:
		return slot.kind == CritSlot.Kind.ARTEMIS)
	var emit := func(_ty: StringName, _e: Dictionary) -> void:
		pass
	CriticalHits.hit_slot(v[0], LoadedDice.new(), emit, a, Location.RT, fcs[0])
	check(w.artemis_lost, "one critical hit disables Artemis V")
	check_eq(WeaponModes.artemis_bonus(w), 0)
	check_eq(WeaponModes.ammo_kind(w), "artemis_v", "ammunition stays the same")
	var th := ToHitCalc.weapon(v[0], a, w, t)
	check(not th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "Artemis V"))


func test_hostile_ecm_blocks_guidance() -> void:
	var v := _battle()
	var a: Unit = v[1]
	var t: Unit = v[2]
	var ecm_def := UnitDef.from_dict({"id": "test_ecm", "name": "ECM", "tonnage": 50,
			"walk_mp": 4, "equipment": {"CT": ["guardian_ecm"]}}, weapons())
	var jammer := Unit.new(3, ecm_def, 1, hex_at(5, 2), 5)
	v[0].add_unit(jammer)
	var th := ToHitCalc.weapon(v[0], a, a.weapons[0], t)
	check(not th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "Artemis V"),
			"hostile ECM removes the accuracy benefit")
	check(Ecm.artemis_blocked(v[0], a, t, th) != "")
