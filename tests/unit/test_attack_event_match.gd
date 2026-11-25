extends TestCase


func test_packets_match_current_attack() -> void:
	var a := GameEvent.new(GameEvent.WEAPON_FIRED, {"attacker_id": 1, "target_id": 2, "weapon": "LRM 20", "hit": true})
	var left := GameEvent.new(GameEvent.DAMAGE, {"source_id": 1, "unit_id": 2, "source": "LRM 20", "loc": Location.LA})
	var right := GameEvent.new(GameEvent.DAMAGE, {"source_id": 1, "unit_id": 2, "source": "LRM 20", "loc": Location.RL})
	check(AttackEventMatch.belongs(a, left))
	check(AttackEventMatch.belongs(a, right))
	check(not AttackEventMatch.belongs(a, GameEvent.new(GameEvent.DAMAGE, {"source_id": 3, "unit_id": 2})))
	check(not AttackEventMatch.belongs(a, GameEvent.new(GameEvent.DAMAGE, {"source_id": 1, "unit_id": 4})))
	check(AttackEventMatch.belongs(a, GameEvent.new(GameEvent.BUILDING, {"kind": "cover_hit", "unit_id": 2})))


func test_mount_ports_and_interception() -> void:
	check_eq(AttackSockets.port_indices(3, 3, 0, false), [0])
	check_eq(AttackSockets.port_indices(3, 3, 2, false), [2])
	check_eq(AttackSockets.port_indices(12, 2, 1, true), [6, 7, 8, 9, 10, 11])
	check_eq(AttackSockets.port_indices(0, 2, 1, true), [])
	check(not AttackEventMatch.fired({"no_ammo": true}))
	check(not AttackEventMatch.fired({"streak_held": true}))
	check(AttackEventMatch.intercepted({"pod_shot_down": true}))
	check(AttackEventMatch.intercepted({"ams": true, "missiles": 0, "cluster_roll": 2}))
	check(not AttackEventMatch.intercepted({"ams": true, "missiles": 4, "cluster_roll": 7}))
