extends TestCase
## TAG designation (Tag, p. 200): spots for indirect fire before weapons fire.


func _setup() -> Array:
	var rows := []
	for r in 10:
		rows.append("c0 c0 c3 c0 c0" if r == 5 else "c0 c0 c0 c0 c0")
	var s := GameState.new(make_map(rows))
	s.turn = 1
	var a := mech("catapult_cplt_c1", 0, hex_at(2, 9), 0, 1)
	var t := mech("hunchback_hbk4g", 1, hex_at(2, 1), 3, 2)
	var tagger := mech("hellspawn_hsn10sr", 0, hex_at(1, 4), 0, 3)
	for u in [a, t, tagger]:
		s.add_unit(u)
	return [s, a, t, tagger]


func _lrm(u: Unit) -> MountedWeapon:
	for w in u.weapons:
		if w.def.indirect:
			return w
	return null


func _labels(th: ToHit) -> Array:
	return th.mods.map(func(m: Dictionary) -> String: return m["label"])


func test_hit_designates_and_spots_without_firing_mod() -> void:
	var r := _setup()
	var s: GameState = r[0]
	var tagger: Unit = r[3]
	check(Tag.has(tagger.def), "Hellspawn carries TAG")
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	var d := Tag.fire(s, dice, tagger, r[2])
	check(d["hit"], "12 hits")
	check(Tag.designator(s, 0, r[2]) == tagger, "designated for side 0")
	check(Tag.designator(s, 1, r[2]) == null, "not for the enemy")
	s.declared_fire.append({"attacker_id": tagger.id, "weapon_index": 0, "target_id": 2})
	var th := ToHitCalc.weapon(s, r[1], _lrm(r[1]), r[2])
	check(th.possible(), "TAG spots the hidden target: " + th.impossible)
	check_eq(th.spotter_id, tagger.id, "the TAG 'Mech is the spotter")
	check(_labels(th).has("TAG") and not _labels(th).has("spotter firing"), "no spotter-attacking +1: %s" % [_labels(th)])
	var own := ToHitCalc.weapon(s, tagger, tagger.weapons[0], r[2])
	check(not _labels(own).has("spotting"), "TAG doesn't add +1 to its own shots")
	check(Tag.problem(s, tagger) != "", "one TAG a turn")
	s.turn = 2
	check(Tag.designator(s, 0, r[2]) == null, "lasts one turn")


func test_miss_leaves_normal_spotting() -> void:
	var r := _setup()
	var s: GameState = r[0]
	var dice := LoadedDice.new()
	dice.queue_2d6(2)
	check(not Tag.fire(s, dice, r[3], r[2])["hit"], "2 misses")
	check(Tag.designator(s, 0, r[2]) == null, "no designation")
	check_eq(IndirectFire.spotting_target(s, r[3]), -1, "still free to spot")
	check(Tag.used(s, r[3]), "but the TAG is spent")


func test_tag_ignores_targeting_computer_and_breaks() -> void:
	var r := _setup()
	var tagger: Unit = r[3]
	var w: MountedWeapon = Tag.mounts(tagger)[0]
	check(not TargetingComputer.eligible(w.def), "no targeting computer bonus")
	check_eq(w.def.long_range, 15, "TAG reaches 15 hexes")
	for sl: CritSlot in tagger.slots[w.loc]:
		if sl.kind == CritSlot.Kind.GEAR and sl.name == "TAG":
			sl.hit = true
	check(Tag.mounts(tagger).is_empty(), "a critical hit ends it")
	check(Tag.problem(r[0], tagger) != "", "can't designate")


func test_light_tag_and_c3_master() -> void:
	check_eq(Tag._def("c_light_tag").long_range, 9, "light TAG reaches 9")
	var m := mech("cyclops_cp11c", 0, hex_at(1, 1))
	check(Tag.has(m.def) and not Tag.mounts(m).is_empty(), "a C3 Master doubles as TAG")


func test_bot_tags_for_hidden_lrms() -> void:
	var r := _setup()
	check(BotTag.choose(r[0], r[3]) == r[2], "bot designates the target its Catapult can't see")
	(r[1] as Unit).has_fired = true
	check(BotTag.choose(r[0], r[3]) == null, "no point once the Catapult has fired")
