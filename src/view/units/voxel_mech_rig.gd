class_name VoxelMechRig
extends RefCounted
## Constructs damageable geometry and per-chassis leg pivot hierarchy.


static func build(frame: Node3D, upper: Node3D, profile: Dictionary) -> Dictionary:
	var rig := {"parts": {}, "sockets": {}, "hips": [], "knees": [],
			"hocks": [], "ankles": [], "arms": []}
	var torso := VoxelPart.new()
	torso.name = "Torso"
	upper.add_child(torso)
	VoxelMechArt.torso(torso, str(profile.get("shape", "prototype")))
	rig["parts"]["torso"] = torso
	for side in 2:
		add_leg(frame, rig, side, profile)
		add_arm(upper, rig, side, profile)
	return rig


static func add_leg(frame: Node3D, rig: Dictionary, side: int,
		profile: Dictionary) -> void:
	var digi := VoxelChassis.is_digitigrade(profile)
	var jenner := str(profile.get("shape", "")) == "jenner"
	var key := "left_leg" if side == 0 else "right_leg"
	var width := float(profile.get("hip_width", 0.38))
	var hip := Node3D.new()
	hip.name = key + "_hip"
	hip.position = Vector3((-1.0 if side == 0 else 1.0) * width,
			VoxelDigitigradeGait.HIP_HEIGHT if digi else 1.36, 0)
	frame.add_child(hip)
	rig["hips"].append(hip)
	var thigh := VoxelPart.new()
	thigh.name = key
	hip.add_child(thigh)
	if jenner:
		VoxelJennerArt.thigh(thigh)
	else:
		thigh.armor_box(Vector3i(-3, -9, -3), Vector3i(3, -1, 3), 0, 1)
		thigh.fill_box(Vector3i(-4, -3, -4), Vector3i(4, -1, 4), 4)
	thigh.seal(-3)
	rig["parts"][key] = thigh
	rig["sockets"][key] = hip
	var knee := Node3D.new()
	knee.name = key + "_knee"
	knee.position.y = -VoxelGait.THIGH
	hip.add_child(knee)
	rig["knees"].append(knee)
	var shin := VoxelPart.new()
	shin.name = key + "_shin"
	knee.add_child(shin)
	if jenner:
		VoxelJennerArt.shin(shin)
	else:
		shin.armor_box(Vector3i(-3, -9, -3), Vector3i(3, -1, 3), 0, 1)
		shin.fill_box(Vector3i(-4, -2, -4), Vector3i(4, 0, 4), 4)
	shin.seal()
	rig["parts"][key + "_shin"] = shin
	rig["sockets"][key + "_shin"] = knee
	var end_pivot: Node3D = knee
	if digi:
		var hock := Node3D.new()
		hock.name = key + "_hock"
		hock.position.y = -VoxelDigitigradeGait.SHIN
		knee.add_child(hock)
		rig["hocks"].append(hock)
		var meta := VoxelPart.new()
		meta.name = key + "_metatarsal"
		hock.add_child(meta)
		if jenner:
			VoxelJennerArt.metatarsal(meta)
			meta.seal()
		else:
			VoxelMechArt.metatarsal(meta)
		rig["parts"][key + "_metatarsal"] = meta
		rig["sockets"][key + "_metatarsal"] = hock
		end_pivot = hock
	else:
		rig["hocks"].append(null)
	var ankle := Node3D.new()
	ankle.name = key + "_ankle"
	ankle.position.y = -(VoxelDigitigradeGait.METATARSAL if digi
			else VoxelGait.SHIN)
	end_pivot.add_child(ankle)
	rig["ankles"].append(ankle)
	var foot := VoxelPart.new()
	foot.name = key + "_foot"
	ankle.add_child(foot)
	if jenner:
		VoxelJennerArt.foot(foot)
	else:
		foot.armor_box(Vector3i(-4, -2, -10 if digi else -9),
				Vector3i(4, 1, 4), 4, 1)
	foot.seal()
	rig["parts"][key + "_foot"] = foot


static func add_arm(upper: Node3D, rig: Dictionary, side: int,
		profile: Dictionary) -> void:
	var key := "left_arm" if side == 0 else "right_arm"
	var width := float(profile.get("arm_width", 1.03))
	var shoulder := Node3D.new()
	shoulder.name = key + "_shoulder"
	shoulder.position = Vector3((-1.0 if side == 0 else 1.0) * width, 0.17, 0)
	upper.add_child(shoulder)
	rig["arms"].append(shoulder)
	var arm := VoxelPart.new()
	arm.name = key
	shoulder.add_child(arm)
	VoxelMechArt.arm(arm, str(profile.get("arm", "standard")), side)
	rig["parts"][key] = arm
	rig["sockets"][key] = shoulder
