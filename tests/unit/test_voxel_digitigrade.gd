extends TestCase
## Digitigrade IK, stance contact, separate pivots, chassis mapping and stabilization.


func test_digitigrade_feet_swap_positions() -> void:
	var forward := VoxelDigitigradeGait.foot_target(0.0)
	var rear := VoxelDigitigradeGait.foot_target(0.5)
	check(forward.x > 0.40, "left toe must lead")
	check(rear.x < -0.25, "right toe must trail")
	check(VoxelDigitigradeGait.foot_target(0.5).x < 0.0, "left switches behind")
	check(VoxelDigitigradeGait.foot_target(1.0).x > 0.0, "right switches ahead")


func test_digitigrade_toes_stay_planted_and_swing() -> void:
	for p in [0.0, 0.2, 0.5]:
		check(is_equal_approx(VoxelDigitigradeGait.foot_target(p).y,
				VoxelDigitigradeGait.TOE_HEIGHT), "stance toe lifted")
	check(VoxelDigitigradeGait.foot_target(0.78).y >
			VoxelDigitigradeGait.TOE_HEIGHT + 0.20, "swing clearance too low")


func test_digitigrade_three_link_ik_hits_toe_target() -> void:
	for i in 40:
		var p := float(i) / 40.0
		var angles := VoxelDigitigradeGait.sample(p)
		var a := VoxelDigitigradeGait.THIGH
		var b := VoxelDigitigradeGait.SHIN
		var c := VoxelDigitigradeGait.METATARSAL
		var hip := angles.x
		var knee := hip + angles.y
		var hock := knee + angles.z
		var toe := hock + angles.w
		var fwd := a * sin(hip) + b * sin(knee) + c * sin(hock)
		var down := a * cos(hip) + b * cos(knee) + c * cos(hock)
		var target := VoxelDigitigradeGait.foot_target(p)
		check(absf(fwd - target.x) < 0.005, "toe horizontal miss phase %.2f" % p)
		check(absf(down - (VoxelDigitigradeGait.HIP_HEIGHT - target.y)) < 0.005,
				"toe vertical miss phase %.2f" % p)
		check(absf(toe) < 0.0001, "toe pitch should be level phase %.2f" % p)


func test_chassis_catalog_maps_to_existing_unit_data() -> void:
	var entries := VoxelChassis.all()
	check_eq(entries.size(), 6, "five unit silhouettes plus baseline")
	for profile in entries:
		var id := str(profile["id"])
		if id != "prototype":
			check(FileAccess.file_exists("res://data/units/%s.json" % id),
					"model profile does not match a game unit: " + id)


func test_digitigrade_rig_has_real_hock_and_metatarsal() -> void:
	var model := VoxelMech.new()
	model.profile_id = "jenner_jr7d"
	model.build()
	model.stand()
	check(model.is_digitigrade(), "Jenner needs digitigrade gait")
	check(model.hocks[0] != null and model.hocks[1] != null,
			"digitigrade hocks missing")
	check(model.parts.has("right_leg_metatarsal"), "third segment lacks damage mesh")
	check_eq(model.hocks[0].get_parent(), model.knees[0],
			"hock must hinge from knee/shin")
	check_eq(model.ankles[0].get_parent(), model.hocks[0],
			"toe pivot must hinge from hock")
	model.free()


func test_humanoid_remains_two_link_and_silhouettes_differ() -> void:
	var atlas := VoxelMech.new()
	atlas.profile_id = "atlas_as7d"
	atlas.build()
	var jenner := VoxelMech.new()
	jenner.profile_id = "jenner_jr7d"
	jenner.build()
	check(not atlas.is_digitigrade(), "Atlas should have humanoid gait")
	check(atlas.hocks[0] == null, "Atlas should not have hock")
	check(atlas.parts["torso"].cells.size() != jenner.parts["torso"].cells.size(),
			"chassis body geometry should differ")
	atlas.free()
	jenner.free()


func test_stabilization_reduces_upper_rotation() -> void:
	var model := VoxelMech.new()
	model.profile_id = "catapult_cplt_c1"
	model.build()
	var upper := model.get_node("Frame/UpperBody") as Node3D
	model.upper_stability = 0.0
	model._pose(0.25)
	var unfiltered := absf(upper.rotation.x)
	model.upper_stability = 0.9
	model._pose(0.25)
	check(unfiltered > 0.02, "test requires nonzero natural gait motion")
	check(absf(upper.rotation.x) < unfiltered * 0.20,
			"upper chassis not stabilized")
	check(absf(upper.rotation.z) < 0.01, "upper roll too large")
	model.free()
