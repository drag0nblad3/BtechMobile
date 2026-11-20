class_name VoxelFineDetail
extends RefCounted
## Extra geometry and material accents applied AFTER 2x voxel subdivision.
## The original 75 mm silhouette is retained; added 37.5 mm grooves and
## one-cell bevels are real destructible geometry, not a texture overlay.


static func decorate(part: VoxelPart) -> void:
	match part.name:
		"Torso":
			_torso(part)
		"left_arm", "right_arm":
			_laser_pod(part)
		"left_leg", "right_leg":
			_thigh(part)
		"left_leg_shin", "right_leg_shin":
			_shin(part)
		"left_leg_metatarsal", "right_leg_metatarsal":
			_hock(part)
		"left_leg_foot", "right_leg_foot":
			_toes(part)


static func _torso(part: VoxelPart) -> void:
	# One fine-voxel canopy separator on an otherwise continuous glass panel.
	_paint(part, Vector3i(0, 4, -30), Vector3i(0, 5, -25), 1)
	_paint(part, Vector3i(-2, 2, -39), Vector3i(-2, 2, -36), 1)
	_paint(part, Vector3i(1, 2, -39), Vector3i(1, 2, -36), 1)
	# Remove only the extreme upper corner of the forward beak.
	_carve(part, Vector3i(-2, 1, -42), Vector3i(-2, 1, -42))
	_carve(part, Vector3i(1, 1, -42), Vector3i(1, 1, -42))
	# Thin, separately colored engine grilles and narrow hull panel seams.
	for z in [11, 14, 17, 20]:
		_paint(part, Vector3i(-11, 3, z), Vector3i(-7, 3, z), 1)
		_paint(part, Vector3i(6, 3, z), Vector3i(10, 3, z), 1)
	for z in [1, 5, 9]:
		_paint(part, Vector3i(-18, 0, z), Vector3i(-18, 2, z), 1)
		_paint(part, Vector3i(17, 0, z), Vector3i(17, 2, z), 1)
	# The rack's four missiles now have a narrow one-cell rim.
	for x in [-4, 2]:
		for y in [6, 10]:
			_paint(part, Vector3i(x, y, -14), Vector3i(x + 1, y, -14), 3)


static func _laser_pod(part: VoxelPart) -> void:
	# A finer two-tone muzzle shroud and vents between the two barrels.
	for y in [-4, 2]:
		part.paint_box(Vector3i(-3, y, -22), Vector3i(2, y, -22), 2)
		part.paint_box(Vector3i(-5, y + 1, -19),
				Vector3i(3, y + 1, -19), 1)
	for z in [1, 5, 9]:
		part.paint_box(Vector3i(-5, 6, z), Vector3i(3, 6, z), 1)


static func _thigh(part: VoxelPart) -> void:
	# Narrow layered knee wear plates and exposed rotor cap highlights.
	for y in [-18, -14, -10]:
		part.paint_box(Vector3i(-7, y, -6), Vector3i(5, y, -6), 1)
	for x in [-10, 10]:
		part.paint_box(Vector3i(x, -21, -1), Vector3i(x, -20, 1), 3)


static func _shin(part: VoxelPart) -> void:
	# Alternating narrow armor/piston strakes preserve open side channels.
	for y in [-6, -10, -14, -18]:
		part.paint_box(Vector3i(-4, y, -8), Vector3i(3, y, -8), 0)
	part.paint_box(Vector3i(-1, -17, 6), Vector3i(1, -6, 6), 3)
	for x in [-8, 8]:
		part.paint_box(Vector3i(x, -22, -1), Vector3i(x, -20, 1), 3)


static func _hock(part: VoxelPart) -> void:
	for x in [-6, 6]:
		part.paint_box(Vector3i(x, -2, 0), Vector3i(x, -1, 0), 3)
	part.paint_box(Vector3i(-2, -10, -2), Vector3i(1, -10, 1), 1)


static func _toes(part: VoxelPart) -> void:
	# Sub-cube dark parting lines between foot armor and each narrow claw.
	for x in [-6, 0, 6]:
		part.paint_box(Vector3i(x, -4, -17), Vector3i(x, -4, -17), 1)
		part.carve_box(Vector3i(x, -2, -22), Vector3i(x, -2, -22))


## The original micro-sculpt was authored for a 2x grid. Rescale only the
## Jenner torso accents when its cockpit uses 3x (25 mm) voxels, preserving
## their world positions and true negative spaces instead of shifting them.
static func _grid_lower(point: Vector3i, factor: int) -> Vector3i:
	return Vector3i(floori(float(point.x * factor) / 2.0),
			floori(float(point.y * factor) / 2.0),
			floori(float(point.z * factor) / 2.0))


static func _grid_upper(point: Vector3i, factor: int) -> Vector3i:
	return Vector3i(ceili(float((point.x + 1) * factor) / 2.0) - 1,
			ceili(float((point.y + 1) * factor) / 2.0) - 1,
			ceili(float((point.z + 1) * factor) / 2.0) - 1)


static func _paint(part: VoxelPart, low: Vector3i, high: Vector3i,
		material_id: int) -> void:
	part.paint_box(_grid_lower(low, part.detail_scale),
			_grid_upper(high, part.detail_scale), material_id)


static func _carve(part: VoxelPart, low: Vector3i, high: Vector3i) -> void:
	part.carve_box(_grid_lower(low, part.detail_scale),
			_grid_upper(high, part.detail_scale))
