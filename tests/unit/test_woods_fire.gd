extends TestCase
## Setting woods alight with flamers (book p. 123).

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


## Light woods at 0203, water at 0201; a Firestarter just south of the woods.
func _setup() -> Array:
	events.clear()
	var s := GameState.new(MapLoader.from_dict({"rows": ["c0 w0d1 c0", "c0 c0 c0", "c0 L0 c0", "c0 c0 c0", "c0 c0 c0"]}, terrain()))
	var a := mech("firestarter_fs9h", 0, Hex.from_label("0204"), 0, 1)
	s.add_unit(a)
	return [s, a, Hex.from_label("0203")]



func _flamers(a: Unit) -> Array[int]:
	var out: Array[int] = []
	for i in a.weapons.size():
		if a.weapons[i].def.id == "flamer" and not a.weapons[i].rear:
			out.append(i)
	return out


func test_two_flamer_hits_light_the_woods() -> void:
	var v := _setup()
	var s: GameState = v[0]
	var a: Unit = v[1]
	var c: Vector2i = v[2]
	var fl := _flamers(a)
	check(fl.size() >= 2, "Firestarter has flamers")
	var th := BuildingFire.to_hit(s, a, a.weapons[fl[0]], c)
	check(th.possible(), th.impossible)
	check(th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "woods hex" and m["value"] == -4))
	check_eq(th.auto_hit, "", "only buildings next door are automatic hits")
	BuildingFire.resolve(s, LoadedDice.new(), _emit, a, a.weapons[fl[0]], c, th)
	check(events[0].data["hit"])
	check(Explainer.text(events[0], s, ExplainLevel.FULL).contains("the light woods at 0203"))
	check_eq(int(s.fire_heat[c]), 2)
	var one := s.fire_heat.duplicate()
	Fire.end_phase(s, _emit)
	check(not s.map.get_tile(c).on_fire, "2 heat isn't enough")
	s.fire_heat = one
	BuildingFire.resolve(s, LoadedDice.new(), _emit, a, a.weapons[fl[1]], c, th)
	Fire.end_phase(s, _emit)
	check(s.map.get_tile(c).on_fire, "4 heat in one phase lights it")
	check_eq(events[-1].data["name"], "Light Woods")
	check_eq(BuildingFire.to_hit(s, a, a.weapons[fl[0]], c).impossible, "Already burning")


func test_only_flamers_and_only_woods() -> void:
	var v := _setup()
	var s: GameState = v[0]
	var a: Unit = v[1]
	var c: Vector2i = v[2]
	var ml := -1
	for i in a.weapons.size():
		if not a.weapons[i].def.heat_damage:
			ml = i
	check_eq(BuildingFire.to_hit(s, a, a.weapons[ml], c).impossible,
			"Only heat-causing weapons (flamers) can set woods alight")
	check(not BuildingFire.to_hit(s, a, a.weapons[_flamers(a)[0]], Hex.from_label("0103")).possible(), "clear can't burn")
	check(not WoodsFire.can_light(s.map.get_tile(Hex.from_label("0201"))), "water can't burn")
	var opts := FireOptions.declare(s, a, [{"weapon": _flamers(a)[0], "hex": c}])
	check_eq(opts.size(), 1, "the controller accepts a shot at the woods")
