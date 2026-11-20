class_name VoxelMechRig
extends RefCounted
## Constructs damageable geometry and per-chassis leg pivot hierarchy.


static func build(frame: Node3D, upper: Node3D, profile: Dictionary,
		detail: int = 1, meshes: bool = true) -> Dictionary:
	var rig := {"parts": {}, "sockets": {}, "hips": [], "knees": [],
			"hocks": [], "ankles": [], "arms": []}
	var torso := _new_part(upper, "Torso", profile, detail, meshes)
	VoxelMechArt.torso(torso, str(profile.get("shape", "prototype")))
	rig["parts"]["torso"] = torso
	for side in 2:
		add_leg(frame, rig, side, profile, detail, meshes)
		add_arm(upper, rig, side, profile, detail, meshes)
	return rig


static func add_leg(frame: Node3D, rig: Dictionary, side: int,
		profile: Dictionary, detail: int = 1, meshes: bool = true) -> void:
	var digi := VoxelChassis.is_digitigrade(profile)
	var jenner := str(profile.get("shape", "")) == "jenner"
	var key := "left_leg" if side == 0 else "right_leg"
	var width := float(profile.get("hip_width", 0.38))
	var hip := Node3D.new()
	hip.name = key + "_hip"
	hip.position = Vector3((-1.0 if side == 0 else 1.0) * width,
			VoxelJennerGait.HIP_HEIGHT if jenner else (VoxelDigitigradeGait.HIP_HEIGHT if digi else 1.36), 0)
	frame.add_child(hip)
	rig["hips"].append(hip)
	var thigh := _new_part(hip, key, profile, detail, meshes)
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
	knee.position.y = -(VoxelJennerGait.THIGH if jenner else VoxelGait.THIGH)
	hip.add_child(knee)
	rig["knees"].append(knee)
	var shin := _new_part(knee, key + "_shin", profile, detail, meshes)
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
		hock.position.y = -(VoxelJennerGait.SHIN if jenner else VoxelDigitigradeGait.SHIN)
		knee.add_child(hock)
		rig["hocks"].append(hock)
		var meta := _new_part(hock, key + "_metatarsal", profile,
				detail, meshes)
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
	ankle.position.y = -(VoxelJennerGait.METATARSAL if jenner else
			(VoxelDigitigradeGait.METATARSAL if digi else VoxelGait.SHIN))
	end_pivot.add_child(ankle)
	rig["ankles"].append(ankle)
	var foot := _new_part(ankle, key + "_foot", profile, detail, meshes)
	if jenner:
		VoxelJennerArt.foot(foot)
	else:
		foot.armor_box(Vector3i(-4, -2, -10 if digi else -9),
				Vector3i(4, 1, 4), 4, 1)
	foot.seal()
	rig["parts"][key + "_foot"] = foot


static func add_arm(upper: Node3D, rig: Dictionary, side: int,
		profile: Dictionary, detail: int = 1, meshes: bool = true) -> void:
	var key := "left_arm" if side == 0 else "right_arm"
	var width := float(profile.get("arm_width", 1.03))
	var shoulder := Node3D.new()
	shoulder.name = key + "_shoulder"
	shoulder.position = Vector3((-1.0 if side == 0 else 1.0) * width, 0.17, 0)
	upper.add_child(shoulder)
	rig["arms"].append(shoulder)
	var arm := _new_part(shoulder, key, profile, detail, meshes)
	VoxelMechArt.arm(arm, str(profile.get("arm", "standard")), side)
	rig["parts"][key] = arm
	rig["sockets"][key] = shoulder


## Every part is configured BEFORE its first seal() to avoid building a coarse
## mesh only to rebuild an 8x denser one. Meshes can be suppressed for catalog
## voxel-count sampling, which only needs the exact occupied cell dictionaries.
static func _new_part(parent: Node3D, part_name: String, profile: Dictionary,
		detail: int, meshes: bool) -> VoxelPart:
	var part := VoxelPart.new()
	part.name = part_name
	part.detail_scale = clampi(detail, 1, 2)
	part.detail_style = str(profile.get("shape", ""))
	part.mesh_enabled = meshes
	parent.add_child(part)
	return part
