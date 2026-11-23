extends TestCase
## Canonical source identities, launcher data and Streak one-shot lifecycle.

const IDS := [
    "fafnir_fnr5", "huron_warrior_hurwor4l", "naginata_ngc3a",
    "anubis_abs3l", "no_dachi_nda1k", "hellstar", "war_dog_wrdg02fc",
    "men_shen_ms1o", "blood_asp_prime", "fire_falcon_prime", "regent_prime",
]
const BV := [2636, 1530, 1954, 951, 1708, 3084, 1814, 1550, 2654, 1451, 2437]


func test_source_identity_and_muls() -> void:
    var db := designs()
    for i in IDS.size():
        var d: UnitDef = db.get_def(IDS[i])
        check(d != null, IDS[i] + " is selectable")
        if d == null:
            continue
        check_eq(d.bv, BV[i], d.id + " MUL BV")
        check(int(d.source.get("mul_id", 0)) > 0, d.id + " official identity")
        check(String(d.source.get("megamek", "")).ends_with(".mtf"), d.id + " MTF")
        check_eq(d.source.get("bv", ""), "mul", d.id + " BV provenance")
        check(String(d.source.get("mul_url", "")).begins_with(
            "https://masterunitlist.battletech.com/units/"), d.id + " source URL")


func test_distinctive_record_sheet_mounts() -> void:
    var db := designs()
    check_eq(_count(db.get_def("fafnir_fnr5"), "heavy_gauss_rifle"), 2)
    check_eq(_count(db.get_def("hellstar"), "c_er_ppc"), 4)
    check_eq(_count(db.get_def("naginata_ngc3a"), "lrm15"), 3)
    check_eq(_count(db.get_def("blood_asp_prime"), "c_heavy_medium_laser"), 4)
    check_eq(_count(db.get_def("war_dog_wrdg02fc"), "streak_srm2_os"), 2)
    check_eq(_count(db.get_def("regent_prime"), "c_lb20x_ac"), 1)
    check(db.get_def("men_shen_ms1o").omni, "Men Shen Omni flag")
    check(db.get_def("fire_falcon_prime").omni, "Fire Falcon Omni flag")
    check(db.get_def("anubis_abs3l").armor_type == "stealth", "Anubis stealth armor")
    check_eq(db.get_def("no_dachi_nda1k").melee.size(), 1, "No-Dachi sword")


func test_new_weapons_match_megamek() -> void:
    var wdb := weapons()
    var names := ["elrm5", "elrm10", "elrm15", "elrm20"]
    var racks := [5, 10, 15, 20]
    var shots := [18, 9, 6, 4]
    var bv := [67, 133, 200, 268]
    for i in names.size():
        var w: WeaponDef = wdb.get_def(names[i])
        check(w != null, names[i] + " exists")
        if w == null:
            continue
        check_eq(w.missiles, racks[i])
        check_eq(w.ammo_per_ton, shots[i])
        check_eq(w.bv, bv[i])
        check_eq([w.min_range, w.short_range, w.medium_range, w.long_range],
            [10, 12, 22, 38])
        check(w.indirect, names[i] + " uses standard spotter rules")
    var ppc: WeaponDef = wdb.get_def("c_enhanced_ppc")
    check_eq([ppc.damage, ppc.heat, ppc.slots, ppc.bv], [12, 15, 3, 329])


func test_streak_one_shot_kept_without_lock() -> void:
    var a := _unit(1, 0, hex_at(0, 1), {"RA": ["streak_srm2_os"]})
    var target := _unit(2, 1, hex_at(3, 1), {"RA": ["medium_laser"]})
    var s := GameState.new(open_map(7, 4))
    s.add_unit(a)
    s.add_unit(target)
    var w: MountedWeapon = a.weapons[0]
    var dice := LoadedDice.new()
    dice.queue_2d6(2)
    var events := []
    WeaponFire.resolve(s, dice, func(kind: StringName, entry: Dictionary) -> void:
        events.append([kind, entry]), a, w, target, ToHitCalc.weapon(s, a, w, target))
    check_eq(w.spent, false, "failed Streak lock retains the entire one-shot launcher")
    check(events.any(func(e: Array) -> bool:
        return e[0] == GameEvent.WEAPON_FIRED and e[1].get("streak_held", false)),
        "reports no lock without firing")


func _unit(id: int, side: int, pos: Vector2i, eq: Dictionary) -> Unit:
    var d := UnitDef.from_dict({"id": "batch_%d" % id, "name": "Test",
        "tonnage": 40, "walk_mp": 4, "armor": {"HD": 9, "CT": 22, "LT": 15,
        "RT": 15, "LA": 12, "RA": 12, "LL": 15, "RL": 15},
        "equipment": eq}, weapons())
    return Unit.new(id, d, side, pos, 2)


func _count(d: UnitDef, weapon_id: String) -> int:
    var count := 0
    for m: Dictionary in d.weapon_mounts:
        if (m["weapon"] as WeaponDef).id == weapon_id:
            count += 1
    return count
