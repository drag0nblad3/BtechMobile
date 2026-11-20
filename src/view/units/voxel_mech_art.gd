class_name VoxelMechArt
extends RefCounted
## Distinct procedural chassis silhouettes for prototype comparison.
## Paintable voxel regions stay real VoxelParts and retain local erosion.


static func torso(part: VoxelPart, shape: String) -> void:
	match shape:
		"atlas":
			part.armor_box(Vector3i(-9, -6, -5), Vector3i(8, 4, 5), 0, 1)
			part.fill_box(Vector3i(-12, -2, -4), Vector3i(-8, 4, 4), 4)
			part.fill_box(Vector3i(7, -2, -4), Vector3i(11, 4, 4), 4)
			part.fill_box(Vector3i(-4, 5, -3), Vector3i(3, 8, 2), 4)
			part.fill_box(Vector3i(-3, 5, -4), Vector3i(2, 6, -4), 2)
			part.fill_box(Vector3i(-6, -5, -6), Vector3i(5, -3, -5), 0)
		"hunchback":
			part.armor_box(Vector3i(-7, -5, -4), Vector3i(6, 3, 4), 0, 1)
			part.fill_box(Vector3i(3, 2, -4), Vector3i(12, 10, 4), 4)
			part.fill_box(Vector3i(6, 4, -9), Vector3i(9, 7, -5), 1)
			part.fill_box(Vector3i(7, 5, -11), Vector3i(8, 6, -10), 3)
			part.fill_box(Vector3i(-4, 4, -3), Vector3i(1, 6, 2), 4)
			part.fill_box(Vector3i(-3, 4, -4), Vector3i(0, 5, -4), 2)
		"wolverine":
			part.armor_box(Vector3i(-7, -5, -4), Vector3i(6, 3, 4), 0, 1)
			part.fill_box(Vector3i(-5, 0, -6), Vector3i(4, 2, -5), 4)
			part.fill_box(Vector3i(-3, 4, -3), Vector3i(2, 7, 2), 4)
			part.fill_box(Vector3i(-2, 5, -4), Vector3i(1, 6, -4), 2)
			part.fill_box(Vector3i(-8, -4, 3), Vector3i(-6, 1, 5), 5)
		"jenner":
			VoxelJennerArt.torso(part)
		"catapult":
			part.armor_box(Vector3i(-6, -5, -4), Vector3i(5, 4, 5), 0, 1)
			part.fill_box(Vector3i(-4, -1, -9), Vector3i(3, 2, -5), 4)
			part.fill_box(Vector3i(-3, 0, -10), Vector3i(2, 1, -10), 2)
			part.fill_box(Vector3i(-3, 5, 1), Vector3i(2, 6, 4), 5)
		_:
			part.armor_box(Vector3i(-8, -5, -4), Vector3i(7, 3, 4), 0, 1)
			part.fill_box(Vector3i(-4, 0, -6), Vector3i(3, 3, -5), 2)
			part.fill_box(Vector3i(-2, -4, -6), Vector3i(1, -3, -5), 4)
			part.fill_box(Vector3i(-4, 4, -2), Vector3i(3, 7, 2), 4)
			part.fill_box(Vector3i(-4, 5, -4), Vector3i(3, 6, -3), 2)
			part.fill_box(Vector3i(-5, -4, -6), Vector3i(4, -2, -5), 0)
			part.fill_box(Vector3i(-10, 0, -4), Vector3i(-7, 3, 4), 4)
			part.fill_box(Vector3i(6, 0, -4), Vector3i(9, 3, 4), 4)
			part.fill_box(Vector3i(-8, 2, -3), Vector3i(-5, 4, 3), 5)
			part.fill_box(Vector3i(4, 2, -3), Vector3i(7, 4, 3), 5)
	VoxelRosterSculpt.torso(part, shape)
	part.seal()


static func arm(part: VoxelPart, style: String, side: int,
		shape: String = "") -> void:
	match style:
		"heavy":
			part.armor_box(Vector3i(-4, -9, -4), Vector3i(4, 1, 4), 0, 1)
			part.fill_box(Vector3i(-5, -2, -4), Vector3i(5, 1, 4), 4)
			part.fill_box(Vector3i(-2, -8, -10), Vector3i(2, -5, -4), 1)
			part.fill_box(Vector3i(-3, -8, -11), Vector3i(3, -6, -10), 3)
		"cannon":
			part.armor_box(Vector3i(-3, -7, -3), Vector3i(3, 1, 3), 0, 1)
			part.fill_box(Vector3i(-2, -7, -7), Vector3i(2, -5, -4), 1)
		"lasers":
			VoxelJennerArt.arm(part, side)
		"missile_pods":
			part.armor_box(Vector3i(-5, -3, -5), Vector3i(5, 5, 4), 4, 1)
			part.fill_box(Vector3i(-4, -2, -7), Vector3i(4, 4, -6), 1)
			for x in [-3, 0, 3]:
				for y in [-1, 2]:
					part.fill_box(Vector3i(x, y, -8), Vector3i(x, y, -8), 3)
		_:
			part.armor_box(Vector3i(-3, -8, -3), Vector3i(3, 1, 3), 0, 1)
			part.fill_box(Vector3i(-4, -2, -4), Vector3i(4, 1, 4), 4)
			part.fill_box(Vector3i(-2, -7, -11), Vector3i(2, -4, -4), 1)
			part.fill_box(Vector3i(-3, -7, -11), Vector3i(3, -5, -10), 3)
	if not shape.is_empty():
		VoxelRosterSculpt.arm(part, shape, side)
	part.seal(-2 if style != "missile_pods" else 1)


static func metatarsal(part: VoxelPart) -> void:
	part.armor_box(Vector3i(-2, -4, -2), Vector3i(2, -1, 2), 4, 1)
	part.fill_box(Vector3i(-3, -1, -3), Vector3i(3, 0, 3), 1)
	part.seal()
