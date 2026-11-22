extends TestCase
## PPC capacitors (PpcCapacitor, p. 188): charge instead of firing, +5 damage.

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _setup() -> Array:
	events.clear()
	var s := GameState.new(open_map(10, 6))
	s.turn = 1
	var a := mech("wolfhound_wlf2h", 0, hex_at(1, 1), 2, 1)
	var t := mech("hunchback_hbk4g", 1, hex_at(4, 2), 5, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func _ppc(u: Unit) -> MountedWeapon:
	for w in u.weapons:
		if w.capacitor:
			return w
	return null


func test_design_links_capacitor() -> void:
	var r := _setup()
	var a: Unit = r[1]
	var w := _ppc(a)
	check(w != null and w.def.id == "heavy_ppc", "Wolfhound WLF-2H: heavy PPC with a capacitor")
	var names := (a.slots[w.loc] as Array).map(func(sl: CritSlot) -> String: return sl.name)
	check(names.has("PPC Capacitor"), "a slot of its own")
	check_eq(WeaponModes.modes(w), ["", PpcCapacitor.CHARGE] as Array[String], "can charge when empty")


func test_charge_then_fire() -> void:
	var r := _setup()
	var s: GameState = r[0]
	var a: Unit = r[1]
	var t: Unit = r[2]
	var w := _ppc(a)
	w.mode = PpcCapacitor.CHARGE
	check(not ToHitCalc.weapon(s, a, w, t).possible(), "charging means not firing")
	PpcCapacitor.end_phase(s, _emit)
	check(w.cap_charged, "charged")
	check_eq(a.heat_generated, PpcCapacitor.HEAT, "5 heat while charged")
	check(events.any(func(e: GameEvent) -> bool: return e.type == GameEvent.CAPACITOR), "logged")
	check_eq(WeaponModes.modes(w), [""] as Array[String], "a charged PPC must use the charge")
	a.heat_generated = 0
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	dice.queue_2d6(7)
	var ct := t.armor[Location.CT]
	WeaponFire.resolve(s, dice, _emit, a, w, t, ToHitCalc.weapon(s, a, w, t))
	check_eq(a.heat_generated, w.def.heat + PpcCapacitor.HEAT, "PPC heat + 5")
	check_eq(ct - t.armor[Location.CT], w.def.damage + PpcCapacitor.DAMAGE, "+5 damage")
	check(not w.cap_charged, "charge used")
	PpcCapacitor.end_phase(s, _emit)
	check_eq(a.heat_generated, w.def.heat + PpcCapacitor.HEAT, "no holding heat once fired")


func test_charged_crit_explodes() -> void:
	var r := _setup()
	var s: GameState = r[0]
	var a: Unit = r[1]
	var w := _ppc(a)
	w.cap_charged = true
	check(PpcCapacitor.explodes(s, a, w), "charged: explodes")
	PpcCapacitor.explode(s, LoadedDice.new(), _emit, a, w, w.loc)
	var ex := events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.AMMO_EXPLOSION)
	check_eq(int(ex[0].data["base"]), 2 * (w.def.slots + 1), "2 per combined slot")
	check(w.destroyed and w.capacitor_lost, "both wrecked")
	var w2 := _ppc(_setup()[1])
	check(not PpcCapacitor.explodes(r[0], a, w2), "empty capacitor doesn't explode")
	s.declared_fire.append({"attacker_id": a.id, "weapon_index": a.weapons.find(w), "target_id": 2})
	w.cap_charged = true
	check(not PpcCapacitor.explodes(s, a, w), "declared firing this phase: not charged")
