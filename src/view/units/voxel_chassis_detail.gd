class_name VoxelChassisDetail
extends RefCounted
## Sculpt at the REAL 25/37.5 mm grid after each chassis part is subdivided.
## Only exposed armor is painted/carved; core IK joints and part transforms
## are unchanged. All marks remain destructible voxel cells.


static func decorate(part: VoxelPart) -> void:
	if part.detail_style == "atlas":
		_atlas(part)
	elif part.detail_style == "catapult":
		_catapult(part)


static func _atlas(part: VoxelPart) -> void:
	match part.name:
		"Torso":
			# 25 mm armored brow; split the Atlas's narrow forward visor.
			part.paint_box(Vector3i(-10, 21, -12), Vector3i(9, 22, -12), 1)
			part.paint_box(Vector3i(0, 15, -12), Vector3i(0, 20, -12), 1)
			part.paint_box(Vector3i(-8, 16, -13), Vector3i(-7, 17, -13), 2)
			part.paint_box(Vector3i(6, 16, -13), Vector3i(7, 17, -13), 2)
			# Real recessed chest plate joins and offset side armor strakes.
			for y in [-14, -7, 0, 7]:
				part.carve_box(Vector3i(-15, y, -15),
						Vector3i(14, y, -15))
				part.paint_box(Vector3i(-15, y + 1, -14),
						Vector3i(14, y + 1, -14), 1)
			for x in [-32, 26]:
				for y in [-3, 3, 9]:
					part.paint_box(Vector3i(x, y, -13),
							Vector3i(x + 4, y, -13), 1)
			# Raised removable armor studs around the upper shoulder collar.
			for x in [-21, -12, 12, 21]:
				part.fill_box(Vector3i(x, 12, -15),
						Vector3i(x + 1, 13, -15), 4)
			# Roof ventilation slits use genuine 1-microvoxel grooves.
			for z in [-2, 4, 10]:
				part.carve_box(Vector3i(-8, 24, z),
						Vector3i(7, 24, z))
		"left_arm", "right_arm":
			# Heavier articulated forearm armor and short dark vent lines.
			for y in [-3, -9, -15]:
				part.paint_box(Vector3i(-7, y, -9),
						Vector3i(7, y, -9), 1)
			part.paint_box(Vector3i(-4, -14, -22),
					Vector3i(3, -13, -22), 3)
			for x in [-7, 7]:
				part.paint_box(Vector3i(x, -4, 0),
						Vector3i(x, 0, 0), 5)
		"left_leg", "right_leg", "left_leg_shin", "right_leg_shin":
			# Parallel steel shinwear strips make joints legible at 37.5 mm.
			for y in [-4, -9, -14]:
				part.paint_box(Vector3i(-5, y, -6),
						Vector3i(5, y, -6), 1)
			part.paint_box(Vector3i(-6, -17, 0),
					Vector3i(-6, -12, 0), 3)
			part.paint_box(Vector3i(6, -17, 0),
					Vector3i(6, -12, 0), 3)
		"left_leg_foot", "right_leg_foot":
			for x in [-5, 0, 5]:
				part.paint_box(Vector3i(x, -4, -14),
						Vector3i(x, -4, -10), 1)


static func _catapult(part: VoxelPart) -> void:
	match part.name:
		"Torso":
			# 37.5 mm cockpit with a split windshield and raised eyebrow; scale
			# the marks with the *actual* part resolution, not the pod resolution.
			var scale := part.detail_scale
			var front := -10 * scale
			part.paint_box(Vector3i(0, 0, front),
					Vector3i(0, 2 * scale - 1, front), 1)
			part.paint_box(Vector3i(-3 * scale + 1, scale, front),
					Vector3i(3 * scale - 2, 2 * scale - 1, front), 2)
			part.paint_box(Vector3i(-3 * scale + 1, -1, front),
					Vector3i(3 * scale - 2, -1, front), 4)
			# Engine cooling grilles and recessed horizontal chest plate lines.
			for z in [-2, 0, 2, 4]:
				part.paint_box(Vector3i(-4 * scale, 4 * scale, z * scale),
						Vector3i(3 * scale, 4 * scale, z * scale), 1)
			for y in [-4, -2, 0, 2]:
				part.carve_box(Vector3i(-5 * scale, y * scale, -4 * scale),
						Vector3i(4 * scale, y * scale, -4 * scale))
			for x in [-5, 4]:
				part.paint_box(Vector3i(x * scale, -2 * scale, 4 * scale),
						Vector3i(x * scale, 3 * scale, 4 * scale), 5)
		"left_arm", "right_arm":
			_missile_pod(part)
		"left_leg", "right_leg", "left_leg_shin", "right_leg_shin":
			# Long armored digitigrade spring casings and hydraulic rods.
			for y in [-3, -9, -15]:
				part.paint_box(Vector3i(-5, y, -6),
						Vector3i(5, y, -6), 1)
			for x in [-7, 7]:
				part.paint_box(Vector3i(x, -12, 2),
						Vector3i(x, -5, 2), 3)
		"left_leg_metatarsal", "right_leg_metatarsal":
			part.paint_box(Vector3i(-3, -6, -4),
					Vector3i(3, -6, -4), 1)
		"left_leg_foot", "right_leg_foot":
			for x in [-6, 0, 6]:
				part.paint_box(Vector3i(x, -4, -17),
						Vector3i(x, -4, -10), 1)


static func _missile_pod(part: VoxelPart) -> void:
	# Six oversized ports in the old silhouette are replaced by a real 5x3
	# grid of fifteen *recessed* LRM launch tubes per pod. Every port has its
	# own rim and open mouth; the dark material at the rear is deeper in the
	# geometry, not a flat overlay.
	part.fill_box(Vector3i(-13, -8, -27), Vector3i(14, 14, -25), 4)
	part.fill_box(Vector3i(-12, -7, -28), Vector3i(13, 13, -28), 1)
	for col in 5:
		var x := -10 + col * 5
		for row in 3:
			var y := -5 + row * 7
			part.fill_box(Vector3i(x - 1, y - 1, -29),
					Vector3i(x + 2, y + 2, -29), 0)
			part.carve_box(Vector3i(x, y, -29),
					Vector3i(x + 1, y + 1, -27))
			part.paint_box(Vector3i(x, y, -26),
					Vector3i(x + 1, y + 1, -26), 3)
	# Boxed side rails reinforce the pod silhouette without covering tubes.
	for x in [-14, 15]:
		part.fill_box(Vector3i(x, -8, -25),
				Vector3i(x, 14, -21), 4)
	for y in [-9, 15]:
		part.fill_box(Vector3i(-14, y, -25),
				Vector3i(15, y, -22), 1)
	# Narrow service access lines and rear vent bars.
	for z in [-6, 0, 6, 12]:
		part.paint_box(Vector3i(-12, 15, z),
				Vector3i(12, 15, z), 1)
