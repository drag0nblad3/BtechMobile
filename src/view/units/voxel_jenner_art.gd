class_name VoxelJennerArt
extends RefCounted
## First chassis-specific Jenner JR7-D voxel blockout.
## Distinctive forward cockpit, four side lasers, CT SRM-4 and light reverse legs.
## All shapes use real damageable cells; no image/sprite overlays.


static func torso(part: VoxelPart) -> void:
	# Wide, shallow rear engine deck above a narrowed forward hull.
	part.armor_box(Vector3i(-8, -5, -2), Vector3i(7, 3, 7), 0, 1)
	part.fill_box(Vector3i(-9, -2, 1), Vector3i(8, 2, 6), 4)
	part.fill_box(Vector3i(-7, 4, 1), Vector3i(6, 4, 5), 4)
	# Distinct projecting side engine housings, leaving a visible waist.
	part.armor_box(Vector3i(-10, -3, -1), Vector3i(-7, 3, 5), 4, 1)
	part.armor_box(Vector3i(6, -3, -1), Vector3i(9, 3, 5), 4, 1)
	# Sloped forward beak: narrow at its nose and wider toward rear.
	for z in range(-15, -5):
		var w := 3 if z < -12 else (4 if z < -9 else 5)
		var floor_y := -2 if z < -12 else -3
		var roof_y := 1 if z < -11 else 2
		part.fill_box(Vector3i(-w, floor_y, z), Vector3i(w - 1, roof_y, z), 4)
	# Cockpit side windows and forward wraparound windshield.
	part.fill_box(Vector3i(-3, 0, -16), Vector3i(2, 1, -15), 2)
	part.fill_box(Vector3i(-4, 1, -14), Vector3i(3, 2, -12), 2)
	part.fill_box(Vector3i(-5, 0, -12), Vector3i(-5, 1, -9), 1)
	part.fill_box(Vector3i(4, 0, -12), Vector3i(4, 1, -9), 1)
	# Forward nose and broad brow frame the panoramic glass.
	part.fill_box(Vector3i(-3, -2, -17), Vector3i(2, -1, -15), 0)
	part.fill_box(Vector3i(-2, -1, -18), Vector3i(1, 0, -17), 4)
	part.fill_box(Vector3i(-2, 1, -17), Vector3i(1, 1, -17), 2)
	part.fill_box(Vector3i(-3, 0, -16), Vector3i(-3, 1, -15), 1)
	part.fill_box(Vector3i(2, 0, -16), Vector3i(2, 1, -15), 1)
	part.fill_box(Vector3i(-4, 3, -12), Vector3i(3, 3, -9), 0)
	part.fill_box(Vector3i(-3, 3, -13), Vector3i(2, 3, -13), 4)
	# Center torso four-tube SRM4 launcher: actual individually exposed cells.
	part.fill_box(Vector3i(-3, 3, -6), Vector3i(2, 5, -3), 1)
	for x in [-2, 1]:
		for y in [3, 5]:
			part.fill_box(Vector3i(x, y, -7), Vector3i(x, y, -7), 3)
			part.fill_box(Vector3i(x, y, -8), Vector3i(x, y, -8), 1)
	# Striped rear heat exchangers and engine exhaust nozzles.
	for x in [-6, 4]:
		part.fill_box(Vector3i(x, 0, 8), Vector3i(x + 2, 2, 9), 1)
		part.fill_box(Vector3i(x, 1, 10), Vector3i(x + 2, 2, 10), 5)
		part.fill_box(Vector3i(x, -4, 7), Vector3i(x + 2, -3, 9), 1)
	part.fill_box(Vector3i(-2, -4, 8), Vector3i(1, -3, 9), 1)
	part.fill_box(Vector3i(-2, -4, 10), Vector3i(1, -4, 10), 3)
	# Additional fender separation and belly armor.
	part.fill_box(Vector3i(-4, -6, -2), Vector3i(3, -5, 3), 1)
	part.fill_box(Vector3i(-3, -6, -4), Vector3i(2, -6, 0), 4)


static func arm(part: VoxelPart, side: int) -> void:
	# Stubby, side-mounted pods rather than full humanoid arms.
	part.armor_box(Vector3i(-4, -4, -3), Vector3i(3, 2, 5), 4, 1)
	part.fill_box(Vector3i(-4, 3, -2), Vector3i(3, 3, 3), 0)
	part.fill_box(Vector3i(-3, -5, 1), Vector3i(2, -4, 4), 1)
	# Two independent medium laser apertures on each side.
	for y in [-2, 1]:
		part.fill_box(Vector3i(-3, y - 1, -8), Vector3i(2, y + 1, -4), 1)
		part.fill_box(Vector3i(-3, y - 1, -10), Vector3i(2, y + 1, -9), 4)
		part.fill_box(Vector3i(-2, y, -11), Vector3i(1, y, -10), 2)
	# Small colored pod insignia and upper vents.
	part.fill_box(Vector3i(-2, 4, 1), Vector3i(1, 4, 3), 5)
	part.fill_box(Vector3i(-3, -3, 5), Vector3i(2, -2, 6), 1)


static func thigh(part: VoxelPart) -> void:
	# Narrow waist, armored forward femur, larger rounded hip joint.
	part.armor_box(Vector3i(-3, -9, -2), Vector3i(3, -2, 2), 0, 1)
	part.fill_box(Vector3i(-4, -3, -3), Vector3i(4, -1, 3), 4)
	part.fill_box(Vector3i(-4, -1, -2), Vector3i(4, 0, 2), 1)
	part.fill_box(Vector3i(-2, -6, -4), Vector3i(2, -3, -3), 4)
	part.fill_box(Vector3i(-3, -10, -2), Vector3i(3, -8, 2), 1)
	part.fill_box(Vector3i(-4, -10, -1), Vector3i(4, -9, 1), 4)


static func shin(part: VoxelPart) -> void:
	# Two-step tapered shin casing gives a distinct knee/hock silhouette.
	part.armor_box(Vector3i(-3, -4, -3), Vector3i(3, -1, 3), 0, 1)
	part.fill_box(Vector3i(-4, -2, -2), Vector3i(4, 0, 2), 4)
	part.armor_box(Vector3i(-3, -8, -1), Vector3i(3, -5, 2), 0, 1)
	part.fill_box(Vector3i(-2, -10, 0), Vector3i(2, -7, 2), 4)
	part.fill_box(Vector3i(-4, -10, 0), Vector3i(4, -9, 1), 1)
	part.fill_box(Vector3i(-3, -5, -4), Vector3i(3, -4, -3), 4)


static func metatarsal(part: VoxelPart) -> void:
	# Narrow hock with visibly articulated, downward-sloping third link.
	part.armor_box(Vector3i(-2, -4, -2), Vector3i(2, -1, 2), 0, 1)
	part.fill_box(Vector3i(-3, -2, -3), Vector3i(3, -1, 3), 4)
	part.fill_box(Vector3i(-2, -5, -1), Vector3i(2, -4, 1), 1)
	part.fill_box(Vector3i(-3, -1, -3), Vector3i(3, 0, 3), 4)


static func foot(part: VoxelPart) -> void:
	# Distinct central heel with three projecting toes instead of a flat slab.
	part.armor_box(Vector3i(-3, -1, -4), Vector3i(3, 1, 4), 4, 1)
	part.fill_box(Vector3i(-4, -2, 0), Vector3i(4, -1, 3), 0)
	for x in [-3, 0, 3]:
		part.fill_box(Vector3i(x, -2, -9), Vector3i(x + 1, 0, -4), 4)
		part.fill_box(Vector3i(x, -2, -11), Vector3i(x + 1, -1, -10), 0)
		part.fill_box(Vector3i(x, 0, -8), Vector3i(x, 0, -6), 1)
	part.fill_box(Vector3i(-2, -1, 4), Vector3i(2, 1, 6), 1)
