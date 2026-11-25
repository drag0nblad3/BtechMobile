extends TestCase
## Special Pilot Abilities, batch 4 (Campaign Operations pp. 74-82):
## Marksman, Dodge, Fist Fire, Zweihander, Hopper.

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _of(type: StringName) -> Array:
	return events.filter(func(e: GameEvent) -> bool: return e.type == type)


func _labels(th: ToHit) -> Array:
	return th.mods.map(func(m: Dictionary) -> String: return m["label"])


func _pair(a_id: String, t_id: String) -> Array:
	events.clear()
	var s := GameState.new(open_map(6, 6))
	var a := mech(a_id, 0, hex_at(2, 3), 0, 1)
	var t := mech(t_id, 1, Hex.neighbor(hex_at(2, 3), 0), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func test_marksman_aims_one_weapon_at_a_moving_mech() -> void:
	var r := _pair("hunchback_hbk4g", "jenner_jr7d")
	var s: GameState = r[0]
	var a: Unit = r[1]
	var t: Unit = r[2]
	t.coord = hex_at(2, 0)
	t.move_mode = MoveMode.Kind.RUN
	t.hexes_moved = 3
	var shots := [{"weapon": gun_index(a, "medium_laser"), "target_id": 2, "aim": Location.CT},
			{"weapon": gun_index(a, "ac20"), "target_id": 2}]
	var plain := FireOptions.declare(s, a, shots)
	check_eq(plain.size(), 2, "no aim without the ability")
	check_eq(plain[0]["to_hit"].aim_loc, -1)
	Spa.grant(a.pilot, Spa.MARKSMAN)
	var aimed := FireOptions.declare(s, a, shots)
	check_eq(aimed.size(), 1, "only the aimed weapon fires")
	check_eq(aimed[0]["to_hit"].aim_loc, Location.CT)
	check(_labels(aimed[0]["to_hit"]).has("aimed with targeting computer"), "+3 like a targeting computer")
	check_eq(AimedShot.problem(s, gun(a, "medium_laser"), t, Location.HEAD, ToHitCalc.weapon(s, a, gun(a, "medium_laser"), t), a) != "", true, "never the head")
	a.hexes_moved = 1
	check_eq(FireOptions.declare(s, a, shots).size(), 2, "it had to stand still")
	a.hexes_moved = 0
	a.marksman_used = true
	t.coord = Hex.neighbor(a.coord, 0)
	check(PhysicalOptions.for_target(s, a, t).is_empty(), "no physical attack after a Marksman shot")


func test_dodge_beats_a_weaker_hit() -> void:
	var r := _pair("atlas_as7d", "hunchback_hbk4g")
	var s: GameState = r[0]
	Spa.grant(r[2].pilot, Spa.DODGE)
	s.declared_physical.append_array(PhysicalOptions.declare(s, r[1], [{"kind": "punch", "limb": Location.LA, "target_id": 2}]))
	PhysicalPhase.resolve(s, LoadedDice.new([3, 3, 6, 6]), _emit)  # hits by 2, dodges by 7
	var hit: GameEvent = _of(GameEvent.PHYSICAL)[0]
	check(not hit.data["hit"] and hit.data["dodged"], "dodged")
	check(_of(GameEvent.DAMAGE).is_empty(), "no damage")
	events.clear()
	s.declared_physical.append_array(PhysicalOptions.declare(s, r[1], [{"kind": "punch", "limb": Location.LA, "target_id": 2}]))
	PhysicalPhase.resolve(s, LoadedDice.new([3, 3, 2, 3]), _emit)  # dodge margin 0 is lower
	check(_of(GameEvent.PHYSICAL)[0].data["hit"], "the punch lands")
	check(not r[2].prone, "a failed dodge doesn't knock it down")


func test_fist_fire_follows_a_punch() -> void:
	var r := _pair("hunchback_hbk4g", "jenner_jr7d")
	var s: GameState = r[0]
	Spa.grant(r[1].pilot, Spa.FIST_FIRE)
	s.declared_physical.append_array(PhysicalOptions.declare(s, r[1], [{"kind": "punch", "limb": Location.LA, "target_id": 2}]))
	PhysicalPhase.resolve(s, LoadedDice.new([3, 3, 2]), _emit)
	var shot := _of(GameEvent.WEAPON_FIRED)
	check_eq(shot.size(), 1, "the arm laser fires")
	check(shot[0].data["fist_fire"] and _labels_of(shot[0].data["mods"]).has("fist fire"), "at -1")
	var dmg := _of(GameEvent.DAMAGE)
	check_eq(dmg.size(), 2, "punch and laser")
	check_eq(dmg[1].data["loc"], dmg[0].data["loc"], "same location")
	check_eq(dmg[1].data["amount"], 5)
	check(gun(r[1], "medium_laser").fired, "the laser counts as fired")


func _labels_of(mods: Array) -> Array:
	return mods.map(func(m: Dictionary) -> String: return m["label"])


func test_zweihander_two_handed_hatchet() -> void:
	var r := _pair("hatchetman_hct5s", "hunchback_hbk4g")
	var s: GameState = r[0]
	var a: Unit = r[1]
	var none := PhysicalOptions.for_target(s, a, r[2]).filter(func(o: Dictionary) -> bool: return o["kind"] == Zweihander.KIND)
	check(none.is_empty(), "needs the ability")
	Spa.grant(a.pilot, Spa.ZWEIHANDER)
	var two := PhysicalOptions.for_target(s, a, r[2]).filter(func(o: Dictionary) -> bool: return o["kind"] == Zweihander.KIND)
	check_eq(two.size(), 2, "punch and hatchet")
	var axe: Dictionary = two.filter(func(o: Dictionary) -> bool: return o["weapon"] == "hatchet")[0]
	check_eq(axe["damage"], 9 + 4, "hatchet + 1 per 10 full tons")
	check_eq(axe["limb"], Location.RA)
	var fist: Dictionary = two.filter(func(o: Dictionary) -> bool: return o["weapon"] == "punch")[0]
	check_eq(fist["damage"], 5 + 4)
	s.declared_physical.append_array(PhysicalOptions.declare(s, a, [{"kind": Zweihander.KIND, "limb": Location.RA, "target_id": 2}]))
	PhysicalPhase.resolve(s, LoadedDice.new([1, 1]), _emit)
	check(a.psr_pending.any(func(p: Dictionary) -> bool: return p["reason"] == "missed a two-handed blow"), "a miss needs a roll")
	s.declared_physical.append_array(PhysicalOptions.declare(s, a, [{"kind": Zweihander.KIND, "limb": Location.RA, "target_id": 2}]))
	PhysicalPhase.resolve(s, LoadedDice.new([6, 6]), _emit)
	var checks := _of(GameEvent.CRIT_CHECK).filter(func(e: GameEvent) -> bool: return e.data["unit_id"] == a.id)
	check_eq(checks.size(), 1, "the swinging arm risks a critical hit")
	check_eq(checks[0].data["loc"], Location.RA)
	r[2].coord = hex_at(2, 4)  # behind it
	a.coord = hex_at(2, 3)
	check(Zweihander.problem(s, a, r[2]) != "", "front arc only")


func test_hopper_can_stay_standing() -> void:
	var r := _pair("hunchback_hbk4g", "jenner_jr7d")
	var s: GameState = r[0]
	var u: Unit = r[1]
	Damage.destroy_location(u, Location.LL)
	Psr.resolve_pending(s, LoadedDice.new([6, 6]), _emit, u)
	check(u.prone, "without Hopper the 'Mech falls")
	r = _pair("hunchback_hbk4g", "jenner_jr7d")
	s = r[0]
	u = r[1]
	Spa.grant(u.pilot, Spa.HOPPER)
	Damage.destroy_location(u, Location.LL)
	Psr.resolve_pending(s, LoadedDice.new([6, 6]), _emit, u)
	check(not u.prone, "a good roll keeps it up")
	u.psr_pending.clear()
	Damage.destroy_location(u, Location.RL)
	check(u.prone or ToHitCalc.is_immobile(u), "two legs gone is beyond any Hopper")
	r = _pair("hunchback_hbk4g", "jenner_jr7d")
	s = r[0]
	u = r[1]
	Spa.grant(u.pilot, Spa.HOPPER)
	Damage.destroy_location(u, Location.LL)
	Psr.resolve_pending(s, LoadedDice.new([1, 1]), _emit, u)
	check(u.prone, "a failed roll still falls")
	var belt := _of(GameEvent.PSR).filter(func(e: GameEvent) -> bool: return e.data["reason"] == "seatbelt check")
	check(not belt.is_empty() and _labels_of(belt.back().data["mods"]).has("Hopper"), "-2 on the pilot's roll")
