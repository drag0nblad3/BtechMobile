class_name VoxelHighFidelityArt
extends RefCounted
## Chassis-specific high-resolution blockouts on the original 75mm authoring
## grid. Seal() subdivides every occupied coarse cell into 37.5mm microvoxels.
## Keep silhouettes recognizable and damageable, not padded with dummy cells.


static func torso(part: VoxelPart, shape: String) -> void:
	match shape:
		"atlas":
			_atlas_torso(part)
		"catapult":
			_catapult_torso(part)


static func arm(part: VoxelPart, style: String, _side: int) -> void:
	match style:
		"heavy":
			_atlas_arm(part)
		"missile_pods":
			_catapult_pod(part)


static func leg(part: VoxelPart, shape: String, section: String) -> void:
	match shape:
		"atlas":
			_atlas_leg(part, section)
		"catapult":
			_catapult_leg(part, section)


static func _atlas_torso(part: VoxelPart) -> void:
	# Enlarged collar/upper mantle; broad armored shoulders remain distinct.
	part.armor_box(Vector3i(-8, 3, -5), Vector3i(7, 7, 5), 4, 1)
	for sign in [-1, 1]:
		var x0 := -15 if sign == -1 else 9
		var x1 := -9 if sign == -1 else 15
		part.armor_box(Vector3i(x0, -3, -6), Vector3i(x1, 6, 6), 4, 1)
		# Projected armor collar, black joint line and raised shoulder rim.
		part.fill_box(Vector3i(x0, 5, -7), Vector3i(x1, 7, 5), 4)
		part.fill_box(Vector3i(x0, -1, -8), Vector3i(x1, 3, -7), 0)
	# Two sloped, separated frontal breastplate stacks.
	for sign in [-1, 1]:
		var x0 := -8 if sign == -1 else 1
		var x1 := -1 if sign == -1 else 8
		part.armor_box(Vector3i(x0, -3, -9), Vector3i(x1, 3, -6), 0, 1)
		part.fill_box(Vector3i(x0 + 1, 2, -10), Vector3i(x1 - 1, 3, -9), 4)
	# Heavy rear heat-exchanger block, with actual projecting vent assemblies.
	part.armor_box(Vector3i(-7, -4, 6), Vector3i(6, 4, 10), 4, 1)
	for x in [-6, -3, 0, 3]:
		part.fill_box(Vector3i(x, 1, 11), Vector3i(x + 1, 4, 12), 1)
		part.fill_box(Vector3i(x, 2, 13), Vector3i(x + 1, 3, 13), 5)
	# Skull-like face and high heavy head, kept proportionate to shoulders.
	part.armor_box(Vector3i(-4, 6, -4), Vector3i(3, 11, 3), 4, 1)
	part.fill_box(Vector3i(-3, 8, -5), Vector3i(2, 10, -5), 0)
	part.fill_box(Vector3i(-3, 9, -6), Vector3i(-1, 9, -6), 2)
	part.fill_box(Vector3i(0, 9, -6), Vector3i(2, 9, -6), 2)
	part.fill_box(Vector3i(-2, 7, -6), Vector3i(1, 7, -6), 1)
	# Front waist/fascia and the rear backpack keep the silhouette broad.
	part.fill_box(Vector3i(-6, -8, -4), Vector3i(5, -6, 5), 0)


static func _atlas_arm(part: VoxelPart) -> void:
	# Thick shoulder plate, deep forearm sleeve and asymmetrical weapon flange.
	part.armor_box(Vector3i(-6, -3, -6), Vector3i(6, 3, 6), 4, 1)
	part.armor_box(Vector3i(-5, -11, -5), Vector3i(5, -3, 5), 0, 1)
	part.fill_box(Vector3i(-6, -6, -6), Vector3i(6, -4, 5), 4)
	part.fill_box(Vector3i(-4, -11, -9), Vector3i(4, -7, -5), 1)
	part.fill_box(Vector3i(-3, -12, -10), Vector3i(3, -10, -8), 0)
	for x in [-4, 4]:
		part.fill_box(Vector3i(x, -10, -5), Vector3i(x, -5, 5), 4)
	part.fill_box(Vector3i(-2, -10, -11), Vector3i(2, -9, -11), 3)


static func _atlas_leg(part: VoxelPart, section: String) -> void:
	match section:
		"thigh":
			# Thick upper-leg shroud and exposed lateral hip hubs.
			part.armor_box(Vector3i(-5, -8, -4), Vector3i(5, -2, 4), 4, 1)
			part.fill_box(Vector3i(-6, -4, -3), Vector3i(6, -1, 3), 0)
			part.fill_box(Vector3i(-5, -10, -4), Vector3i(5, -9, 3), 4)
		"shin":
			# Knee roll cage, broader calf armor and ankle heat baffle.
			part.armor_box(Vector3i(-5, -9, -4), Vector3i(5, -3, 4), 0, 1)
			part.fill_box(Vector3i(-5, -2, -5), Vector3i(5, 0, 4), 4)
			part.fill_box(Vector3i(-4, -9, -5), Vector3i(4, -7, -4), 4)
		"foot":
			part.armor_box(Vector3i(-5, -2, -11), Vector3i(5, 1, 4), 0, 1)
			for x in [-4, 0, 4]:
				part.fill_box(Vector3i(x, -2, -13), Vector3i(x + 2, -1, -11), 4)


static func _catapult_torso(part: VoxelPart) -> void:
	# Swept armored central hull plus a pronounced rear engine deck.
	part.armor_box(Vector3i(-9, -6, -4), Vector3i(8, 6, 9), 0, 1)
	part.fill_box(Vector3i(-8, 5, 5), Vector3i(7, 8, 9), 4)
	part.fill_box(Vector3i(-7, -7, 0), Vector3i(6, -6, 8), 1)
	# Low pointed forward crew canopy under a rigid roof.
	part.armor_box(Vector3i(-6, -2, -12), Vector3i(5, 3, -5), 4, 1)
	part.fill_box(Vector3i(-4, -1, -14), Vector3i(3, 1, -12), 0)
	part.fill_box(Vector3i(-3, 1, -15), Vector3i(2, 2, -12), 2)
	part.fill_box(Vector3i(-5, 3, -10), Vector3i(4, 4, -5), 4)
	part.fill_box(Vector3i(-7, -4, -10), Vector3i(6, -3, -5), 0)
	# Back-mounted jump-jet housings separated by heat vents.
	for x in [-8, 4]:
		part.armor_box(Vector3i(x, -4, 9), Vector3i(x + 4, 5, 12), 4, 1)
		part.fill_box(Vector3i(x + 1, 0, 13), Vector3i(x + 3, 3, 13), 1)
		part.fill_box(Vector3i(x + 1, 1, 14), Vector3i(x + 3, 2, 14), 5)
	# Split roof vent spine and side escape louvers.
	for z in [2, 5, 8]:
		part.fill_box(Vector3i(-3, 7, z), Vector3i(2, 8, z), 1)


static func _catapult_pod(part: VoxelPart) -> void:
	# Each side unit is a self-contained LRM-15 pod, not a human arm.
	part.armor_box(Vector3i(-6, -4, -7), Vector3i(6, 7, 7), 4, 1)
	part.fill_box(Vector3i(-7, -3, -6), Vector3i(-6, 5, 6), 0)
	part.fill_box(Vector3i(6, -3, -6), Vector3i(7, 5, 6), 0)
	part.fill_box(Vector3i(-5, 6, -8), Vector3i(5, 8, 6), 4)
	part.fill_box(Vector3i(-6, -5, -6), Vector3i(6, -4, 5), 1)
	part.fill_box(Vector3i(-5, -3, -9), Vector3i(5, 6, -8), 0)
	# Five rows of three distinct dark rocket mouths, set into muzzle face.
	for x in [-4, 0, 4]:
		for y in [-2, 0, 2, 4, 6]:
			part.carve_box(Vector3i(x, y, -9), Vector3i(x, y, -8))
			part.fill_box(Vector3i(x, y, -7), Vector3i(x, y, -7), 3)
	# Raise the upper rear corner to keep the LRM shoulders recognizable.
	part.fill_box(Vector3i(-4, 8, 1), Vector3i(4, 9, 6), 4)


static func _catapult_leg(part: VoxelPart, section: String) -> void:
	match section:
		"thigh":
			part.armor_box(Vector3i(-5, -8, -4), Vector3i(5, -2, 4), 0, 1)
			part.fill_box(Vector3i(-6, -4, -3), Vector3i(6, 0, 3), 4)
		"shin":
			part.armor_box(Vector3i(-4, -8, -4), Vector3i(4, -2, 4), 4, 1)
			part.fill_box(Vector3i(-5, -3, -3), Vector3i(5, 0, 3), 0)
		"hock":
			part.armor_box(Vector3i(-3, -5, -3), Vector3i(3, 0, 3), 4, 1)
		"foot":
			part.armor_box(Vector3i(-5, -2, -11), Vector3i(5, 1, 4), 4, 1)
			for x in [-4, 0, 4]:
				part.fill_box(Vector3i(x, -2, -13), Vector3i(x + 2, 0, -11), 0)


## Post-subdivision detailing: fine paint and one-cell channels are real voxels
## and remain destructible, not shader effects.
static func fine_detail(part: VoxelPart) -> void:
	if part.detail_style == "atlas":
		_atlas_micro(part)
	elif part.detail_style == "catapult":
		_catapult_micro(part)


static func _atlas_micro(part: VoxelPart) -> void:
	match part.name:
		"Torso":
			# Narrow skull visor divider, grill slots and chest armor seams.
			part.paint_box(Vector3i(-1, 18, -12), Vector3i(0, 19, -12), 1)
			for y in [-1, 3, 7]:
				part.paint_box(Vector3i(-13, y, -20), Vector3i(-5, y, -20), 1)
				part.paint_box(Vector3i(4, y, -20), Vector3i(12, y, -20), 1)
			for x in [-10, -4, 2, 8]:
				part.paint_box(Vector3i(x, 6, 24), Vector3i(x + 1, 7, 25), 3)
		"left_arm", "right_arm":
			for y in [-5, -11, -17]:
				part.paint_box(Vector3i(-11, y, -12), Vector3i(11, y, -12), 1)
		"left_leg", "right_leg", "left_leg_shin", "right_leg_shin":
			for y in [-6, -12, -18]:
				part.paint_box(Vector3i(-9, y, -9), Vector3i(9, y, -9), 1)


static func _catapult_micro(part: VoxelPart) -> void:
	match part.name:
		"Torso":
			# Framed cockpit glass and heat exchanger markings.
			part.paint_box(Vector3i(-1, 2, -30), Vector3i(0, 3, -29), 1)
			for x in [-12, -4, 4, 12]:
				part.paint_box(Vector3i(x, 16, 12), Vector3i(x, 16, 17), 1)
		"left_arm", "right_arm":
			# Small relief grooves on top and separate rims around 15 rockets.
			for x in [-8, 0, 8]:
				for y in [-4, 0, 4, 8, 12]:
					part.paint_box(Vector3i(x, y, -19), Vector3i(x + 1, y, -19), 1)
			for z in [-6, 0, 6]:
				part.paint_box(Vector3i(-11, 15, z), Vector3i(11, 15, z), 1)
		"left_leg", "right_leg", "left_leg_shin", "right_leg_shin":
			for y in [-5, -11, -17]:
				part.paint_box(Vector3i(-8, y, -9), Vector3i(8, y, -9), 1)
