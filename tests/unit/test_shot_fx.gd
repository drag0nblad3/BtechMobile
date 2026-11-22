extends TestCase
## Rendering is covered by the live UI smoke; these are pure contract checks.


func test_weapon_tracer_families() -> void:
	check_eq(ShotFx.style("er_large_laser"), "laser")
	check_eq(ShotFx.style("medium_pulse_laser"), "laser")
	check_eq(ShotFx.style("er_ppc"), "ppc")
	check_eq(ShotFx.style("lrm_15"), "missile")
	check_eq(ShotFx.style("srm_6"), "missile")
	check_eq(ShotFx.style("gauss_rifle"), "ballistic")
	check_eq(ShotFx.style("flamer"), "flame")
	check(ShotFx.MAX_ACTIVE <= 32, "short-lived effects are bounded")
	check(ShotFx.PROJECTILE_TIME < 0.5, "projectiles are visual feedback")


func test_miss_variation_is_stable() -> void:
	var a := ShotFx.miss_offset(3, 11, "lrm_10")
	var b := ShotFx.miss_offset(3, 11, "lrm_10")
	var c := ShotFx.miss_offset(4, 11, "lrm_10")
	check_eq(a, b, "same event produces same miss offset")
	check(a != c, "different attacks have different visual offsets")
	check(a.length() > 0.35 and a.length() < 1.1, "miss stays near target")


func test_blast_profiles_are_lightweight() -> void:
	check(VxBlast.KINDS.has("miss"), "miss has a compact dust puff")
	check(VxBlast.KINDS.has("fall"), "fall has ground dust")
	check(int(VxBlast.KINDS["miss"]["smoke"]) + int(VxBlast.KINDS["miss"]["debris"]) < 20,
		"miss effects remain small on mobile")
