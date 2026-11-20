class_name VoxelRosterSculpt
extends RefCounted
## Chassis-specific physical sculpting, inspired by Claude's JSON model:
## cut-through weapons, layered shells, asymmetric equipment, hollow vents,
## exposed mechanisms. Author in coarse local coordinates BEFORE seal;
## micro-sculpt only on the selected part's real 25/37.5 mm grid AFTER refine.
## Geometry is never consulted by the Total Warfare combat rules.


static func torso(part: VoxelPart, shape: String) -> void:
	match shape:
		"prototype":
			_training_torso(part)
		"hunchback":
			_hunchback_torso(part)
		"wolverine":
			_wolverine_torso(part)


static func arm(part: VoxelPart, shape: String, side: int) -> void:
	match shape:
		"prototype":
			_training_arm(part, side)
		"hunchback":
			_hunchback_arm(part, side)
		"wolverine":
			_wolverine_arm(part, side)


static func leg(part: VoxelPart, shape: String, segment: String) -> void:
	if shape == "prototype" or shape == "hunchback" or shape == "wolverine":
		match segment:
			"thigh":
				# Hinged hip rings, separate front plate and a rear piston.
				part.fill_box(Vector3i(-5, -2, -2), Vector3i(5, -1, 2), 1)
				part.fill_box(Vector3i(-4, -8, -4), Vector3i(3, -4, -3), 4)
				part.fill_box(Vector3i(-2, -7, 4), Vector3i(1, -2, 4), 1)
				for x in [-5, 5]:
					part.fill_box(Vector3i(x, -8, -1), Vector3i(x, -7, 1), 3)
				# True open channels beside the central load-bearing member.
				for x in [-3, 3]:
					part.carve_box(Vector3i(x, -6, 0), Vector3i(x, -4, 1))
			"shin":
				part.fill_box(Vector3i(-4, -8, -4), Vector3i(3, -3, -3), 4)
				part.fill_box(Vector3i(-5, -3, -3), Vector3i(4, -2, 2), 0)
				for x in [-4, 4]:
					part.fill_box(Vector3i(x, -7, 2), Vector3i(x, -3, 3), 1)
					part.fill_box(Vector3i(x, -8, 2), Vector3i(x, -8, 3), 3)
				part.carve_box(Vector3i(-2, -7, 3), Vector3i(1, -5, 3))
			"foot":
				# Three separated armored toe ends and a rear heel bumper.
				for x in [-3, 0, 3]:
					part.fill_box(Vector3i(x, -2, -11),
							Vector3i(x + 1, -1, -9), 4)
					part.fill_box(Vector3i(x, -2, -12),
							Vector3i(x, -2, -12), 0)
				part.fill_box(Vector3i(-3, -2, 5), Vector3i(2, -1, 6), 1)
	elif shape == "catapult":
		match segment:
			"thigh", "shin":
				# Exposed spring strut behind the digitigrade armor.
				part.fill_box(Vector3i(-2, -8, 4), Vector3i(1, -2, 4), 1)
				part.fill_box(Vector3i(-3, -8, 4), Vector3i(2, -8, 4), 3)
			"metatarsal":
				for x in [-3, 3]:
					part.fill_box(Vector3i(x, -3, 0), Vector3i(x, -1, 1), 1)


static func fine(part: VoxelPart) -> void:
	match part.detail_style:
		"prototype":
			_training_fine(part)
		"hunchback":
			_hunchback_fine(part)
		"wolverine":
			_wolverine_fine(part)
		"jenner":
			_jenner_fine(part)
		"atlas":
			_atlas_fine(part)
		"catapult":
			_catapult_fine(part)


static func _training_torso(part: VoxelPart) -> void:
	# Deliberate distinct test chassis, not a featureless anonymous cuboid:
	# squared-off instrumented engine deck, split canopy, twin sensor shoulders.
	part.armor_box(Vector3i(-8, -6, -5), Vector3i(7, 3, 5), 0, 1)
	for side in [-1, 1]:
		var x0 := -11 if side < 0 else 8
		var x1 := -8 if side < 0 else 10
		part.armor_box(Vector3i(x0, -2, -5), Vector3i(x1, 5, 5), 4, 1)
		part.fill_box(Vector3i(x0, 3, -6), Vector3i(x1, 4, -5), 1)
		var exterior := x0 - 1 if side < 0 else x1 + 1
		part.fill_box(Vector3i(exterior, -1, 0),
				Vector3i(exterior, 2, 3), 5)
	for z in range(-9, -4):
		var width := 3 if z < -7 else 5
		part.fill_box(Vector3i(-width, -2, z),
				Vector3i(width - 1, 3, z), 4)
	part.fill_box(Vector3i(-3, 1, -10), Vector3i(2, 2, -9), 2)
	part.fill_box(Vector3i(-4, 3, -8), Vector3i(3, 3, -6), 1)
	part.fill_box(Vector3i(-1, 1, -10), Vector3i(-1, 2, -9), 1)
	# Two physically open dorsal cooling wells with recessed structural floors.
	for x in [-5, 2]:
		part.carve_box(Vector3i(x, 3, 1), Vector3i(x + 2, 3, 4))
		part.fill_box(Vector3i(x, 2, 1), Vector3i(x + 2, 2, 4), 1)
	# Ribbed midline sensor spine, separated antenna, and rear thruster cans.
	part.fill_box(Vector3i(-2, 4, 1), Vector3i(1, 5, 5), 0)
	part.fill_box(Vector3i(-1, 6, 1), Vector3i(0, 7, 2), 1)
	part.fill_box(Vector3i(-1, 8, 2), Vector3i(0, 8, 2), 2)
	for x in [-5, 3]:
		part.fill_box(Vector3i(x, -4, 5), Vector3i(x + 2, 1, 8), 1)
		part.carve_box(Vector3i(x, -2, 8), Vector3i(x + 2, 0, 8))
		part.fill_box(Vector3i(x + 1, -2, 7), Vector3i(x + 1, 0, 7), 3)
	part.fill_box(Vector3i(-5, -7, 0), Vector3i(4, -6, 3), 1)


static func _training_arm(part: VoxelPart, side: int) -> void:
	# One arm has a bored test cannon; the other has an exposed tool head.
	part.armor_box(Vector3i(-5, -9, -4), Vector3i(4, 2, 4), 0, 1)
	part.fill_box(Vector3i(-6, -3, -5), Vector3i(5, 1, 4), 4)
	for y in [-8, -5]:
		part.fill_box(Vector3i(-4, y, -6), Vector3i(3, y + 1, -5), 1)
	if side == 0:
		part.fill_box(Vector3i(-3, -8, -11), Vector3i(2, -4, -5), 1)
		part.fill_box(Vector3i(-4, -8, -12), Vector3i(3, -4, -11), 4)
		part.carve_box(Vector3i(-1, -7, -12), Vector3i(0, -5, -9))
		part.fill_box(Vector3i(-1, -6, -8), Vector3i(0, -5, -8), 3)
	else:
		for x in [-3, 1]:
			part.fill_box(Vector3i(x, -10, -8),
					Vector3i(x + 1, -7, -5), 1)
		part.fill_box(Vector3i(-2, -8, -9), Vector3i(1, -7, -9), 2)
	for z in [2, 4]:
		part.carve_box(Vector3i(-3, 2, z), Vector3i(2, 2, z))


static func _hunchback_torso(part: VoxelPart) -> void:
	# Massive right-shoulder AC/20, small off-center head and exposed waist.
	part.armor_box(Vector3i(2, 1, -5), Vector3i(12, 10, 5), 0, 1)
	part.fill_box(Vector3i(2, 10, -4), Vector3i(12, 11, 4), 4)
	part.fill_box(Vector3i(4, -1, -7), Vector3i(11, 3, -5), 1)
	# Reciprocating autocannon jacket, squared muzzle and real through-hole.
	part.fill_box(Vector3i(5, 5, -12), Vector3i(10, 8, -7), 4)
	part.fill_box(Vector3i(4, 4, -14), Vector3i(11, 9, -12), 1)
	part.carve_box(Vector3i(7, 6, -14), Vector3i(8, 7, -9))
	part.fill_box(Vector3i(7, 6, -8), Vector3i(8, 7, -8), 3)
	for x in [4, 11]:
		part.fill_box(Vector3i(x, 3, -12), Vector3i(x, 10, -8), 0)
	for z in [-11, -8]:
		part.fill_box(Vector3i(4, 9, z), Vector3i(11, 9, z), 1)
	# A narrow cockpit recessed left of the large weapon.
	part.fill_box(Vector3i(-5, 3, -5), Vector3i(0, 7, 2), 4)
	part.fill_box(Vector3i(-4, 5, -7), Vector3i(-1, 6, -6), 2)
	part.fill_box(Vector3i(-4, 7, -6), Vector3i(-1, 7, -5), 1)
	part.fill_box(Vector3i(-3, -1, -7), Vector3i(1, 0, -5), 0)
	# Thick asymmetrical shoulder collar and rear engine cooling banks.
	part.fill_box(Vector3i(-10, 0, -3), Vector3i(-7, 4, 5), 0)
	part.fill_box(Vector3i(-10, 3, 1), Vector3i(-8, 5, 4), 4)
	for x in [-7, 4, 9]:
		part.fill_box(Vector3i(x, -1, 5), Vector3i(x + 2, 4, 8), 1)
		for y in [-1, 1, 3]:
			part.carve_box(Vector3i(x, y, 8), Vector3i(x + 1, y, 8))
	part.fill_box(Vector3i(-5, -7, -2), Vector3i(5, -5, 4), 1)
	part.fill_box(Vector3i(-4, -8, -1), Vector3i(3, -8, 3), 0)
	# Recessed edges emphasize separate upper/lower chest armor.
	for x in [-5, 0]:
		part.carve_box(Vector3i(x, -4, -5), Vector3i(x, -3, -5))


static func _hunchback_arm(part: VoxelPart, side: int) -> void:
	part.armor_box(Vector3i(-5, -10, -4), Vector3i(4, 1, 4), 0, 1)
	part.fill_box(Vector3i(-6, -3, -5), Vector3i(5, 1, 4), 4)
	part.fill_box(Vector3i(-5, -9, -5), Vector3i(4, -6, -4), 0)
	part.fill_box(Vector3i(-3, -10, -8), Vector3i(2, -7, -5), 1)
	for x in [-4, 3]:
		part.fill_box(Vector3i(x, -9, 3), Vector3i(x + 1, -4, 4), 1)
	if side == 1:
		# Stabilization rails and coaxial laser beside the heavy cannon.
		part.fill_box(Vector3i(-3, -7, -11), Vector3i(2, -5, -8), 1)
		part.carve_box(Vector3i(-1, -6, -11), Vector3i(0, -5, -9))
		part.fill_box(Vector3i(-1, -6, -8), Vector3i(0, -5, -8), 2)
	else:
		# Small left manipulator with three spaced knuckles.
		for x in [-3, 0, 3]:
			part.fill_box(Vector3i(x, -12, -5),
					Vector3i(x + 1, -10, -2), 4)
	for z in [2, 4]:
		part.carve_box(Vector3i(-4, 1, z), Vector3i(3, 1, z))


static func _wolverine_torso(part: VoxelPart) -> void:
	# Broad tapered upper shoulders and a low angular armored cockpit.
	part.armor_box(Vector3i(-9, -5, -5), Vector3i(8, 4, 6), 0, 1)
	for z in range(-9, -4):
		var w := 3 if z < -7 else (5 if z < -6 else 7)
		part.fill_box(Vector3i(-w, -3, z), Vector3i(w - 1, 3, z), 4)
	part.fill_box(Vector3i(-3, 4, -8), Vector3i(2, 5, -5), 2)
	part.fill_box(Vector3i(-4, 5, -6), Vector3i(3, 6, -4), 1)
	part.fill_box(Vector3i(-1, 4, -8), Vector3i(0, 5, -7), 1)
	for side in [-1, 1]:
		var x0 := -12 if side < 0 else 8
		var x1 := -8 if side < 0 else 11
		part.armor_box(Vector3i(x0, -2, -3), Vector3i(x1, 5, 5), 4, 1)
		part.fill_box(Vector3i(x0, 4, -5), Vector3i(x1, 5, -3), 0)
		part.fill_box(Vector3i(x0, 5, 2), Vector3i(x1, 6, 5), 1)
	# Six actual recessed SRM-6 ports on the left upper torso.
	part.fill_box(Vector3i(-12, 0, -7), Vector3i(-7, 6, -5), 1)
	for x in [-11, -9, -7]:
		for y in [2, 5]:
			part.fill_box(Vector3i(x - 1, y - 1, -8),
					Vector3i(x, y, -8), 4)
			part.carve_box(Vector3i(x, y, -8),
					Vector3i(x, y, -6))
			part.fill_box(Vector3i(x, y, -5), Vector3i(x, y, -5), 3)
	# Offset right-side armor plate and rear vent-fin banks.
	part.fill_box(Vector3i(7, -4, -7), Vector3i(10, 2, -5), 0)
	for x in [-7, -3, 2, 6]:
		part.fill_box(Vector3i(x, -2, 7), Vector3i(x + 1, 4, 9), 1)
		for y in [-1, 1, 3]:
			part.carve_box(Vector3i(x, y, 9), Vector3i(x + 1, y, 9))
	# Vented belly fairing and hip bar, separated from central chest.
	part.fill_box(Vector3i(-5, -7, -2), Vector3i(4, -5, 4), 1)
	part.fill_box(Vector3i(-4, -8, -1), Vector3i(3, -8, 2), 4)


static func _wolverine_arm(part: VoxelPart, side: int) -> void:
	part.armor_box(Vector3i(-4, -9, -4), Vector3i(4, 2, 4), 0, 1)
	part.fill_box(Vector3i(-5, -3, -4), Vector3i(5, 2, 4), 4)
	part.fill_box(Vector3i(-4, -8, -5), Vector3i(4, -4, -4), 0)
	if side == 1:
		# Off-center long-barreled AC/5, concentric armored muzzle.
		part.fill_box(Vector3i(-3, -7, -15), Vector3i(3, -4, -5), 1)
		part.fill_box(Vector3i(-4, -8, -16), Vector3i(4, -3, -14), 4)
		part.carve_box(Vector3i(-1, -6, -16), Vector3i(1, -5, -11))
		part.fill_box(Vector3i(-1, -6, -10), Vector3i(1, -5, -10), 3)
		for z in [-13, -9, -6]:
			part.fill_box(Vector3i(-4, -8, z), Vector3i(4, -8, z), 0)
	else:
		# Broad left manipulator, separate thumb and finger blocks.
		for x in [-3, 0, 3]:
			part.fill_box(Vector3i(x, -12, -4),
					Vector3i(x + 1, -9, -1), 4)
		part.fill_box(Vector3i(5, -10, -4), Vector3i(6, -8, -2), 1)
	for z in [1, 4]:
		part.carve_box(Vector3i(-3, 2, z), Vector3i(3, 2, z))


static func _training_fine(part: VoxelPart) -> void:
	var s := part.detail_scale
	if part.name == "Torso":
		# Fine slit between split canopy panes and actual exhaust recesses.
		part.paint_box(Vector3i(-s, s, -10 * s),
				Vector3i(-s, 2 * s, -9 * s), 1)
		for x in [-5, 3]:
			part.carve_box(Vector3i(x * s, 0, 7 * s),
					Vector3i((x + 1) * s - 1, s - 1, 8 * s))
			part.paint_box(Vector3i(x * s, 0, 6 * s),
					Vector3i((x + 1) * s - 1, s - 1, 6 * s), 3)
		for z in [1, 3, 5]:
			part.carve_box(Vector3i(-2 * s, 5 * s - 1, z * s),
					Vector3i(s, 5 * s - 1, z * s))
	elif part.name.ends_with("_arm"):
		# One-voxel-width removable top access panels.
		for z in [1, 3]:
			part.carve_box(Vector3i(-3 * s, 2 * s - 1, z * s),
					Vector3i(2 * s, 2 * s - 1, z * s))
	elif part.name.ends_with("_shin"):
		part.paint_box(Vector3i(-3 * s, -7 * s, -4 * s),
				Vector3i(2 * s, -7 * s, -4 * s), 1)


static func _hunchback_fine(part: VoxelPart) -> void:
	var s := part.detail_scale
	if part.name == "Torso":
		# Precise circular-ish cannon bore inside coarse rectangular cavity:
		# cut corner cells and retain an inner exposed gun-metal ring.
		var cx := 7 * s
		var cy := 6 * s
		var front := -14 * s
		for y in range(cy, cy + 2 * s):
			for x in range(cx, cx + 2 * s):
				if (x == cx and y == cy) or (x == cx + 2 * s - 1 and y == cy):
					part.carve_box(Vector3i(x, y, front),
							Vector3i(x, y, front))
		for z in [-8, -5, -2]:
			part.paint_box(Vector3i(4 * s, 9 * s, z * s),
					Vector3i(11 * s, 9 * s, z * s), 1)
		for x in [-7, 4, 9]:
			for y in [0, 2]:
				part.carve_box(Vector3i(x * s, y * s, 8 * s),
						Vector3i((x + 1) * s - 1, y * s, 8 * s))
		# L-shaped roof fairing and small tinted cockpit divider.
		part.paint_box(Vector3i(-3 * s, 5 * s, -7 * s),
				Vector3i(-3 * s, 6 * s, -7 * s), 1)
	elif part.name.ends_with("_arm"):
		for y in [-7, -4]:
			part.carve_box(Vector3i(-2 * s, y * s, -5 * s),
					Vector3i(s, y * s, -5 * s))
	elif part.name.ends_with("_shin"):
		for y in [-8, -4]:
			part.paint_box(Vector3i(-3 * s, y * s, -4 * s),
					Vector3i(2 * s, y * s, -4 * s), 1)


static func _wolverine_fine(part: VoxelPart) -> void:
	var s := part.detail_scale
	if part.name == "Torso":
		# Fine sloped glazing rim and thin stepped grille slats.
		part.paint_box(Vector3i(-3 * s, 5 * s - 1, -7 * s),
				Vector3i(2 * s, 5 * s - 1, -7 * s), 1)
		for z in [-1, 2, 5]:
			part.carve_box(Vector3i(-8 * s, 5 * s - 1, z * s),
					Vector3i(-5 * s, 5 * s - 1, z * s))
			part.carve_box(Vector3i(7 * s, 5 * s - 1, z * s),
					Vector3i(10 * s, 5 * s - 1, z * s))
		# Real extra-fine rim detail around all six individual SRM outlets.
		for x in [-11, -9, -7]:
			for y in [2, 5]:
				part.paint_box(Vector3i(x * s - 1, y * s - 1, -8 * s),
						Vector3i(x * s - 1, y * s + 1, -8 * s), 1)
	elif part.name.ends_with("_arm"):
		for y in [-8, -4]:
			part.paint_box(Vector3i(-4 * s, y * s, -5 * s),
					Vector3i(4 * s - 1, y * s, -5 * s), 1)
		for z in [1, 3]:
			part.carve_box(Vector3i(-3 * s, 2 * s - 1, z * s),
					Vector3i(2 * s, 2 * s - 1, z * s))
	elif part.name.ends_with("_shin"):
		part.paint_box(Vector3i(-3 * s, -7 * s, -4 * s),
				Vector3i(2 * s, -7 * s, -4 * s), 1)


static func _jenner_fine(part: VoxelPart) -> void:
	var s := part.detail_scale
	if s < 3:
		return
	if part.name.ends_with("_arm"):
		# Claude-like layered housings around two *separate* laser emitters.
		# Thin 25 mm muzzle reinforcement and true open cooling channels.
		for y in [-2, 1]:
			part.fill_box(Vector3i(-3 * s, (y - 1) * s, -11 * s - 1),
					Vector3i(2 * s, (y + 1) * s - 1, -11 * s - 1), 4)
			part.carve_box(Vector3i(-2 * s, y * s, -11 * s - 1),
					Vector3i(s - 1, y * s + s - 1, -11 * s - 1))
			part.paint_box(Vector3i(-2 * s, y * s, -11 * s),
					Vector3i(s - 1, y * s + s - 1, -11 * s), 2)
		for z in [0, 2, 4]:
			part.carve_box(Vector3i(-2 * s, 3 * s - 1, z * s),
					Vector3i(s - 1, 3 * s - 1, z * s))
		return
	if part.name != "Torso":
		return
	# In addition to the existing 2x Jenner sculpt, 25 mm hull plating
	# permits visible canopy seam, thin frame lip, and vent-wall bevels.
	for z in range(-18, -10, 2):
		part.paint_box(Vector3i(0, 2 * s, z * s),
				Vector3i(0, 2 * s, z * s + s - 1), 1)
	for z in [1, 3, 5]:
		part.carve_box(Vector3i(-5 * s, 3 * s - 1, z * s),
				Vector3i(-4 * s, 3 * s - 1, z * s))
		part.carve_box(Vector3i(3 * s, 3 * s - 1, z * s),
				Vector3i(4 * s, 3 * s - 1, z * s))
	for x in [-5, 3]:
		part.paint_box(Vector3i(x * s, s, 8 * s),
				Vector3i((x + 1) * s - 1, 2 * s - 1, 8 * s), 1)


static func _atlas_fine(part: VoxelPart) -> void:
	if part.name != "Torso":
		return
	# Distinct visor cheekplate and rear engine exhaust rims, all 25 mm.
	part.paint_box(Vector3i(-9, 18, -16), Vector3i(-6, 18, -16), 1)
	part.paint_box(Vector3i(5, 18, -16), Vector3i(8, 18, -16), 1)
	for x in [-30, 25]:
		for y in [-6, 0, 6]:
			part.carve_box(Vector3i(x, y, 13), Vector3i(x + 2, y, 13))


static func _catapult_fine(part: VoxelPart) -> void:
	if part.name == "Torso":
		var s := part.detail_scale
		for x in [-4, 3]:
			part.paint_box(Vector3i(x * s, -2 * s, 5 * s),
					Vector3i(x * s, 2 * s, 5 * s), 1)
		# Two separated rear jump-jet exhaust housings.
		for x in [-4, 2]:
			part.fill_box(Vector3i(x * s, -3 * s, 6 * s),
					Vector3i((x + 1) * s - 1, -s, 7 * s), 1)
			part.carve_box(Vector3i(x * s, -2 * s, 7 * s),
					Vector3i((x + 1) * s - 1, -s, 7 * s))
	elif part.name.ends_with("_metatarsal"):
		var s := part.detail_scale
		for x in [-3, 3]:
			part.paint_box(Vector3i(x * s, -3 * s, 0),
					Vector3i(x * s, -s, s), 1)
