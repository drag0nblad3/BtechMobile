extends TestCase
## Cinematic queue and selection must avoid camera spam or gameplay RNG.


func test_select_consequential_weapon_families() -> void:
	check_eq(CinematicShotPolicy.weapon_kind({"hit": true, "weapon_id": "lrm_15"}), "missile")
	check_eq(CinematicShotPolicy.weapon_kind({"hit": true, "weapon_id": "er_ppc"}), "pair")
	check_eq(CinematicShotPolicy.weapon_kind({"hit": true, "weapon_id": "gauss_rifle"}), "pair")
	check_eq(CinematicShotPolicy.weapon_kind({"hit": true, "weapon_id": "medium_laser"}), "")
	check_eq(CinematicShotPolicy.weapon_kind({"hit": false, "weapon_id": "lrm_15"}), "")
	check_eq(CinematicShotPolicy.weapon_kind({"hit": true, "no_ammo": true, "weapon_id": "lrm_15"}), "")
	check_eq(CinematicShotPolicy.weapon_kind({"hit": true, "streak_held": true, "weapon_id": "srm_6"}), "")


func test_only_major_movements_take_camera() -> void:
	check(CinematicShotPolicy.follow_move({"mode": MoveMode.Kind.JUMP}))
	check(CinematicShotPolicy.follow_move({"hexes": 5}))
	check(not CinematicShotPolicy.follow_move({"hexes": 1}))
	check(not CinematicShotPolicy.follow_move({"hexes": [1, 2, 3]}))
	check_eq(CinematicDirector.MAX_QUEUE, 2)


func test_missile_camera_track_is_bounded() -> void:
	check_eq(CinematicProjectileTrack.progress(ShotFx.PROJECTILE_TIME), 0.0)
	check_eq(CinematicProjectileTrack.progress(0.0), 1.0)
	check_eq(CinematicProjectileTrack.progress(-1.0), 1.0)
	check_eq(CinematicProjectileTrack.progress(99.0), 0.0)
