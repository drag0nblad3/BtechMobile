extends TestCase
## Stealth armor (Stealth, book pp. 202, 209).


func _def(id: String, eq: Dictionary, armor_type := "standard") -> UnitDef:
	return UnitDef.from_dict({"id": id, "name": id, "tonnage": 50, "walk_mp": 4, "armor_type": armor_type,
			"armor": {"CT": 20, "LT": 20, "RT": 20, "LA": 16, "RA": 16, "LL": 20, "RL": 20, "HD": 9},
			"equipment": eq}, weapons())


## A medium-laser attacker and a stealth 'Mech `dist` hexes away.
func _setup(dist: int) -> Array:
	var s := GameState.new(open_map(16, 4))
	var a := Unit.new(1, _def("a", {"RA": ["medium_laser"], "LA": ["lrm10+artemis"], "LT": ["ammo:lrm10"]}), 0, hex_at(1, 2), 2)
	var t := Unit.new(2, _def("t", {"LT": ["guardian_ecm"], "RT": ["c3_slave"]}, "stealth"), 1, hex_at(1 + dist, 2), 5)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func _mod(th: ToHit) -> int:
	for m: Dictionary in th.mods:
		if m["label"] == "stealth armor":
			return m["value"]
	return 0


func test_range_modifiers() -> void:
	for row: Array in [[2, 0], [5, 1], [8, 2]]:
		var v := _setup(row[0])
		var th := ToHitCalc.weapon(v[0], v[1], v[1].weapons[0], v[2])
		check(th.possible(), "the shot is possible at %d hexes" % row[0])
		check_eq(_mod(th), row[1], "stealth modifier at %d hexes" % row[0])
	var off := _setup(8)
	off[2].stealth_off = true
	check_eq(_mod(ToHitCalc.weapon(off[0], off[1], off[1].weapons[0], off[2])), 0, "switched off: no modifier")


func test_not_a_secondary_target() -> void:
	var v := _setup(5)
	var th := ToHitCalc.weapon(v[0], v[1], v[1].weapons[0], v[2], true)
	check(not th.possible(), "an active stealth 'Mech can't be a secondary target")


func test_needs_its_ecm_and_turns_it_off() -> void:
	var v := _setup(5)
	var t: Unit = v[2]
	check(Stealth.active(t), "on from the start")
	check(not Ecm.working(t), "its ECM doesn't jam while stealth is on")
	check(not Ecm.hostile_at(v[0], 0, v[1].coord), "so the attacker isn't jammed")
	check(not C3.working(t), "no C3 under stealth")
	check(Ecm.jammed(v[0], t), "it acts as if inside hostile ECM")
	t.ecm_lost = true
	check(not Stealth.active(t), "no working ECM: no stealth")
	check_eq(_mod(ToHitCalc.weapon(v[0], v[1], v[1].weapons[0], t)), 0, "and no modifier")


func test_own_artemis_jammed() -> void:
	var v := _setup(5)
	var t: Unit = v[2]
	var a: Unit = v[1]
	var shooter := Unit.new(3, _def("s", {"LA": ["lrm10+artemis"], "LT": ["ammo:lrm10", "guardian_ecm"]}, "stealth"), 1, hex_at(10, 2), 5)
	v[0].add_unit(shooter)
	var th := ToHitCalc.weapon(v[0], shooter, shooter.weapons[0], a)
	check(Ecm.artemis_blocked(v[0], shooter, a, th) != "", "stealth jams its own Artemis")
	check(t != null)


func test_heat_and_switching() -> void:
	var v := _setup(5)
	var t: Unit = v[2]
	var events := []
	var emit := func(type: Variant, d: Dictionary) -> void: events.append([type, d])
	HeatPhase.run(v[0], LoadedDice.new(), emit)
	var heat: Dictionary = events.filter(func(e: Array) -> bool: return e[0] == GameEvent.HEAT and e[1]["unit_id"] == t.id)[0][1]
	check_eq(heat["stealth"], Stealth.HEAT, "10 heat a turn while on")
	check_eq(heat["gained"], 10, "built 10 heat standing still")
	t.stealth_request = 0
	check(Stealth.planned_off(t), "planned off")
	Stealth.apply(emit, t)
	check(t.stealth_off and not Stealth.active(t), "off after the End Phase")
	check(Ecm.working(t), "its ECM works again")
	check_eq(events.back()[0], GameEvent.STEALTH)
	check_eq(Stealth.heat(t), 0, "no heat while off")


func test_official_design() -> void:
	var r := mech("raven_rvn4l", 0, Vector2i.ZERO)
	check(Stealth.has(r.def) and Stealth.active(r), "Raven RVN-4L has working stealth armor")
	check_eq(DesignWeight.total(r.def), 35.0, "weighs 35 tons")
