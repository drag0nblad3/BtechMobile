class_name VoxelJennerArt
extends RefCounted
## Jenner JR7-D profile sculpted as separate destructible voxel parts.
## Forward beveled canopy, shoulder/engine bulges, dorsal four-port SRM,
## twin lasers on each side, exposed knee/hock collars and compact three-toe feet.
## Local shading and empty spaces are authored as voxels, not shader decals.


static func torso(part: VoxelPart) -> void:
	# Inner frame is dark when the layered shell is stripped away.
	part.armor_box(Vector3i(-6, -4, -1), Vector3i(5, 2, 7), 0, 1)
	part.fill_box(Vector3i(-4, -5, 0), Vector3i(3, -4, 5), 1)
	# Stepped, chamfered engine fairing: narrow roof and sloped rear corners.
	for z in range(-1, 9):
		var half_width := 5 if z < 2 else (7 if z < 7 else 5)
		var bottom := -3 if z < 7 else -2
		var roof := 3 if z < 6 else 2
		part.fill_box(Vector3i(-half_width, bottom, z),
				Vector3i(half_width - 1, roof, z), 4)
	# Cut stepped roof chamfers and ventilator wells instead of leaving a
	# single box-shaped roof. The darker wells remain open from above.
	for z in range(0, 6):
		var edge := 5 if z < 2 else 7
		part.carve_box(Vector3i(-edge, 3, z), Vector3i(-edge + 1, 3, z))
		part.carve_box(Vector3i(edge - 2, 3, z), Vector3i(edge - 1, 3, z))
	for x in [-5, 3]:
		part.carve_box(Vector3i(x, 2, 6), Vector3i(x + 1, 3, 7))
		part.fill_box(Vector3i(x, 1, 6), Vector3i(x + 1, 1, 7), 1)
	# Side engine/shoulder housings are separated by recessed inner seams.
	for side in [-1, 1]:
		var x0 := -11 if side < 0 else 7
		var x1 := -7 if side < 0 else 10
		part.armor_box(Vector3i(x0, -2, 1), Vector3i(x1, 2, 7), 4, 1)
		var outer_x := x0 if side < 0 else x1
		part.fill_box(Vector3i(outer_x, -1, 2),
				Vector3i(outer_x, 1, 5), 0)
		part.fill_box(Vector3i(outer_x, 0, 4),
				Vector3i(outer_x, 1, 5), 1)
		# Dark access panel breaks up a broad flat side surface.
		var panel_x := x0 - 1 if side < 0 else x1 + 1
		part.fill_box(Vector3i(panel_x, -1, 2),
				Vector3i(panel_x, 1, 4), 1)
	# Cockpit projects far ahead of the engine block; individually tapered
	# longitudinal slices make a readable angled nose in profile and plan.
	for z in range(-20, -5):
		var width := 2 if z < -18 else (3 if z < -15 else
				(4 if z < -12 else (5 if z < -9 else 6)))
		var floor_y := -2 if z < -17 else -3
		var roof_y := 0 if z < -19 else (1 if z < -17 else
				(2 if z < -11 else 3))
		part.fill_box(Vector3i(-width, floor_y, z),
				Vector3i(width - 1, roof_y, z), 4)
		# Dark hull underside leaves the canopy visually separate.
		if z <= -11:
			part.fill_box(Vector3i(-width + 1, floor_y, z),
					Vector3i(width - 2, floor_y, z), 1)
	# Cut the upper outside corners along the canopy's longitudinal taper.
	# The dark frame and glazing are layered on top after these cuts.
	for z in range(-17, -8):
		var width := 3 if z < -15 else (4 if z < -12 else (5 if z < -9 else 6))
		var roof_y := 2 if z < -11 else 3
		part.carve_box(Vector3i(-width, roof_y, z),
				Vector3i(-width + 1, roof_y, z))
		part.carve_box(Vector3i(width - 2, roof_y, z),
				Vector3i(width - 1, roof_y, z))
	# Small wedge tip rather than a squared-off aquarium canopy.
	part.fill_box(Vector3i(-1, -1, -21), Vector3i(0, 0, -21), 0)
	part.fill_box(Vector3i(-1, 0, -21), Vector3i(0, 0, -21), 2)
	part.fill_box(Vector3i(-2, -1, -20), Vector3i(1, -1, -20), 0)
	# Six-part wraparound canopy: windshield, rooflights, side glazing.
	part.fill_box(Vector3i(-1, 0, -20), Vector3i(0, 0, -20), 2)
	part.fill_box(Vector3i(-2, 0, -19), Vector3i(1, 1, -18), 2)
	part.fill_box(Vector3i(-3, 1, -17), Vector3i(2, 1, -16), 2)
	part.fill_box(Vector3i(-3, 2, -15), Vector3i(2, 2, -13), 2)
	part.fill_box(Vector3i(-3, 2, -12), Vector3i(2, 2, -12), 2)
	for z in range(-17, -11):
		var outer := 3 if z < -15 else (4 if z < -12 else 5)
		part.fill_box(Vector3i(-outer, 0, z), Vector3i(-outer, 1, z), 2)
		part.fill_box(Vector3i(outer - 1, 0, z), Vector3i(outer - 1, 1, z), 2)
	# Dark glass seals and armor brows separate glass from bodywork.
	part.fill_box(Vector3i(-4, 3, -12), Vector3i(3, 3, -10), 0)
	part.fill_box(Vector3i(-5, -2, -11), Vector3i(-5, 0, -10), 1)
	part.fill_box(Vector3i(4, -2, -11), Vector3i(4, 0, -10), 1)
	part.fill_box(Vector3i(-4, -3, -14), Vector3i(3, -3, -12), 0)
	# Four-port SRM4 rack, elevated at the rear of the canopy.
	# Preserve legacy named port coordinates for hit-location tests.
	part.fill_box(Vector3i(-4, 3, -5), Vector3i(3, 6, -2), 1)
	part.fill_box(Vector3i(-4, 6, -6), Vector3i(3, 7, -3), 4)
	part.fill_box(Vector3i(-4, 2, -7), Vector3i(3, 2, -5), 4)
	for x in [-2, 1]:
		for y in [3, 5]:
			part.fill_box(Vector3i(x - 1, y - 1, -7),
					Vector3i(x, y, -6), 0)
			part.fill_box(Vector3i(x, y, -8), Vector3i(x, y, -8), 1)
			part.fill_box(Vector3i(x, y, -7), Vector3i(x, y, -7), 3)
	# Back deck and heat exchanger banks with recessed vent slots.
	for x in [-6, 3]:
		part.fill_box(Vector3i(x, 1, 8), Vector3i(x + 2, 3, 8), 1)
		part.fill_box(Vector3i(x, 1, 9), Vector3i(x + 2, 2, 10), 0)
		part.fill_box(Vector3i(x, 2, 11), Vector3i(x + 2, 2, 11), 5)
		part.fill_box(Vector3i(x, -3, 8), Vector3i(x + 2, -2, 9), 1)
	part.fill_box(Vector3i(-2, -3, 9), Vector3i(1, -2, 10), 1)
	part.fill_box(Vector3i(-1, -3, 11), Vector3i(0, -2, 11), 3)
	# Segmented belly and hip mounts instead of one featureless hull slab.
	part.fill_box(Vector3i(-5, -5, -2), Vector3i(4, -4, -1), 0)
	part.fill_box(Vector3i(-3, -6, 0), Vector3i(2, -5, 3), 1)
	part.fill_box(Vector3i(-4, -4, 5), Vector3i(3, -4, 6), 0)


static func arm(part: VoxelPart, _side: int) -> void:
	# Stubby laser nacelles attached beside the engine fairings.
	part.armor_box(Vector3i(-4, -3, -2), Vector3i(3, 2, 5), 4, 1)
	part.fill_box(Vector3i(-5, -1, 0), Vector3i(-4, 1, 4), 0)
	part.fill_box(Vector3i(3, -1, 0), Vector3i(4, 1, 4), 0)
	part.fill_box(Vector3i(-3, 3, 0), Vector3i(2, 3, 4), 0)
	# Two individually exposed laser barrels with a dark gap between.
	for y in [-2, 1]:
		part.fill_box(Vector3i(-2, y - 1, -9),
				Vector3i(1, y, -3), 1)
		part.fill_box(Vector3i(-3, y - 1, -10),
				Vector3i(2, y, -9), 4)
		part.fill_box(Vector3i(-2, y, -11),
				Vector3i(1, y, -11), 2)
	# Exposed housings and rear heat exchangers.
	part.fill_box(Vector3i(-2, -4, 2), Vector3i(1, -3, 4), 1)
	part.fill_box(Vector3i(-2, 4, 2), Vector3i(1, 4, 3), 5)
	part.fill_box(Vector3i(-2, -1, 6), Vector3i(1, 0, 6), 1)


static func thigh(part: VoxelPart) -> void:
	# 0.78 m femur: separate circular-looking collars at hip and knee.
	part.armor_box(Vector3i(-3, -11, -2), Vector3i(3, -2, 2), 0, 1)
	part.fill_box(Vector3i(-4, -3, -3), Vector3i(4, -1, 3), 4)
	part.fill_box(Vector3i(-3, 0, -2), Vector3i(3, 0, 2), 1)
	part.fill_box(Vector3i(-5, -2, -1), Vector3i(5, -1, 1), 1)
	part.fill_box(Vector3i(-4, -6, -3), Vector3i(4, -4, -2), 4)
	part.fill_box(Vector3i(-3, -8, -3), Vector3i(3, -6, -2), 0)
	# Distinct exposed hip hubs, surrounded by armor but not fused into a
	# solid waist block. Side-facing rotor accents are purely voxel material.
	for x in [-5, 5]:
		part.fill_box(Vector3i(x, -2, 0), Vector3i(x, -1, 0), 3)
	# Knee rotor remains visible underneath the leg plate.
	part.fill_box(Vector3i(-4, -11, -2), Vector3i(4, -10, 2), 1)
	part.fill_box(Vector3i(-5, -11, -1), Vector3i(-5, -10, 1), 4)
	part.fill_box(Vector3i(5, -11, -1), Vector3i(5, -10, 1), 4)


static func shin(part: VoxelPart) -> void:
	# 0.82 m shin. Slim structural strut between distinct actuator joints.
	part.armor_box(Vector3i(-2, -11, -2), Vector3i(2, -1, 2), 0, 1)
	part.fill_box(Vector3i(-4, -2, -2), Vector3i(4, 0, 2), 1)
	part.fill_box(Vector3i(-5, -2, -1), Vector3i(-5, -1, 1), 4)
	part.fill_box(Vector3i(5, -2, -1), Vector3i(5, -1, 1), 4)
	# An angled armor stripe along the forward strut, with negative gaps.
	for y in range(-9, -2):
		var z_front := -3 if y < -6 else -4
		part.fill_box(Vector3i(-3, y, z_front),
				Vector3i(2, y, z_front), 4)
	# Dark piston bundle exposed on rear edge and at the joint.
	part.fill_box(Vector3i(-1, -9, 3), Vector3i(1, -3, 3), 1)
	part.fill_box(Vector3i(-3, -11, -2), Vector3i(3, -10, 2), 4)
	part.fill_box(Vector3i(-4, -11, -1), Vector3i(4, -10, 1), 1)
	part.fill_box(Vector3i(-2, -12, -1), Vector3i(2, -11, 1), 4)
	# Open narrow side channels between the forward armor and rear piston.
	# Leave the central strut and both end joints connected.
	for x in [-2, 2]:
		part.carve_box(Vector3i(x, -8, -1), Vector3i(x, -4, 1))
	part.carve_box(Vector3i(-1, -8, 2), Vector3i(1, -4, 2))
	# A separate external piston on the rear face, linked at both ends.
	part.fill_box(Vector3i(-1, -9, 3), Vector3i(1, -3, 3), 1)
	for y in [-9, -3]:
		part.fill_box(Vector3i(-2, y, 2), Vector3i(2, y, 3), 4)


static func metatarsal(part: VoxelPart) -> void:
	# A third, visible angled link from hock to toes rather than a heel box.
	part.armor_box(Vector3i(-2, -4, -2), Vector3i(2, -1, 2), 0, 1)
	part.fill_box(Vector3i(-3, 0, -1), Vector3i(3, 0, 1), 1)
	part.fill_box(Vector3i(-3, -1, -2), Vector3i(3, -1, 2), 4)
	part.fill_box(Vector3i(-1, -5, -1), Vector3i(1, -4, 1), 1)
	part.fill_box(Vector3i(-3, -4, -1), Vector3i(3, -4, 1), 4)
	# Hock rocker fork: a visible gap either side of the central linkage.
	for x in [-2, 2]:
		part.carve_box(Vector3i(x, -3, -1), Vector3i(x, -2, 1))
	part.fill_box(Vector3i(-1, -3, -1), Vector3i(1, -2, 1), 1)
	for x in [-3, 3]:
		part.fill_box(Vector3i(x, -1, 0), Vector3i(x, 0, 0), 3)


static func foot(part: VoxelPart) -> void:
	# Short three-prong foot with real negative space between toe tips.
	part.armor_box(Vector3i(-3, -1, -3), Vector3i(3, 1, 3), 4, 1)
	part.fill_box(Vector3i(-3, -2, 1), Vector3i(3, -2, 3), 0)
	for x in [-3, 0, 3]:
		part.fill_box(Vector3i(x, -2, -7), Vector3i(x + 1, 0, -3), 4)
		part.fill_box(Vector3i(x, -2, -9), Vector3i(x + 1, -1, -8), 0)
		part.fill_box(Vector3i(x, 0, -6), Vector3i(x, 0, -4), 1)
		# Taper each toe independently to a single-voxel front tip.
		part.fill_box(Vector3i(x, -2, -10), Vector3i(x + 1, -2, -10), 4)
		part.fill_box(Vector3i(x, -2, -11), Vector3i(x, -2, -11), 0)
	part.fill_box(Vector3i(-2, -1, 3), Vector3i(2, 1, 5), 1)
