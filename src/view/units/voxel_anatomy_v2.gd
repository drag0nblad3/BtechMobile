class_name VoxelAnatomyV2
extends RefCounted
## Chassis silhouette pass. Unlike simply subdividing cuboids, every major
## assembly is authored as a tapered solid, bevelled ellipsoid, or bored tube.
## This is art-only. Voxel damage stays local; rules use the record sheet.


static func ellipsoid(p: VoxelPart, center: Vector3, radius: Vector3,
		armor: int, core: int = 1) -> void:
	for x in range(floori(center.x - radius.x), ceili(center.x + radius.x) + 1):
		for y in range(floori(center.y - radius.y), ceili(center.y + radius.y) + 1):
			for z in range(floori(center.z - radius.z), ceili(center.z + radius.z) + 1):
				var v := Vector3((float(x) - center.x) / radius.x,
						(float(y) - center.y) / radius.y,
						(float(z) - center.z) / radius.z)
				var d := v.length_squared()
				if d <= 1.0:
					p.cells[Vector3i(x, y, z)] = armor if d > 0.66 else core


## A superelliptic, vertically tapered hull. As opposed to a box, the waist,
## chest, and rear radii are different. exponent=2.5 keeps a military faceted
## look instead of perfectly round, while avoiding a rectangular silhouette.
static func hull(p: VoxelPart, lower_y: int, upper_y: int,
		waist: Vector2, shoulders: Vector2, mat: int, exponent: float = 2.5,
		offset_x: float = 0.0) -> void:
	for y in range(lower_y, upper_y + 1):
		var t := float(y - lower_y) / maxf(1.0, float(upper_y - lower_y))
		var r := waist.lerp(shoulders, smoothstep(0.0, 1.0, t))
		for x in range(floori(offset_x - r.x), ceili(offset_x + r.x) + 1):
			for z in range(-ceili(r.y), ceili(r.y) + 1):
				var dx := absf((float(x) - offset_x) / r.x)
				var dz := absf(float(z) / r.y)
				var q := pow(dx, exponent) + pow(dz, exponent)
				if q <= 1.0:
					p.cells[Vector3i(x, y, z)] = mat if q > 0.69 else 1


## Circular bored tube along the front/back axis. Its inner channel remains
## real empty space through the muzzle, so a ray can enter the cannon.
static func tube(p: VoxelPart, cx: int, cy: int, z0: int, z1: int,
		outer: float, bore: float, mat: int) -> void:
	for z in range(z0, z1 + 1):
		for x in range(cx - ceili(outer), cx + ceili(outer) + 1):
			for y in range(cy - ceili(outer), cy + ceili(outer) + 1):
				var d := Vector2(float(x - cx), float(y - cy)).length()
				if d <= outer and d > bore:
					p.cells[Vector3i(x, y, z)] = mat
				elif d <= bore:
					p.cells.erase(Vector3i(x, y, z))


static func ring_x(p: VoxelPart, x0: int, x1: int, cy: int, cz: int,
		outer: float, inner: float, mat: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(cy - ceili(outer), cy + ceili(outer) + 1):
			for z in range(cz - ceili(outer), cz + ceili(outer) + 1):
				var d := Vector2(float(y - cy), float(z - cz)).length()
				if d <= outer and d > inner:
					p.cells[Vector3i(x, y, z)] = mat


static func torso(p: VoxelPart, shape: String) -> void:
	match shape:
		"atlas":
			_atlas(p)
		"hunchback":
			_hunchback(p)
		"wolverine":
			_wolverine(p)
		"prototype":
			_prototype(p)
		"catapult":
			_catapult(p)
		"jenner":
			_jenner(p)


static func _atlas(p: VoxelPart) -> void:
	p.cells.clear()
	# V-tapered chest is narrower at the armored waist than the shoulders.
	hull(p, -8, 3, Vector2(5.2, 5.2), Vector2(10.8, 6.6), 0)
	for side in [-1, 1]:
		# Rounded pauldrons, each sloping away from the neck. Not a T-bar.
		ellipsoid(p, Vector3(float(side) * 10.6, 1.5, 0.8),
				Vector3(5.7, 4.4, 6.3), 4)
		var x := -9 if side == -1 else 4
		# Distinct sloped chest plates over a recessed centerline.
		for y in range(-5, 3):
			for xx in range(x, x + 6):
				var front := -7 + floori(float(abs(xx)) * 0.18) + (1 if y < -2 else 0)
				for z in range(front, front + 2):
					p.cells[Vector3i(xx, y, z)] = 4
		# Shoulder actuator rings above each arm pivot.
		ring_x(p, -17 if side < 0 else 14, -13 if side < 0 else 18,
				0, 0, 3.4, 1.8, 8)
		# The two bulky rear coolant blocks are rounded and vented.
		ellipsoid(p, Vector3(float(side) * 8.8, 2.0, 7.1),
				Vector3(3.3, 4.5, 3.4), 8)
		for yy in [-1, 1, 3]:
			p.carve_box(Vector3i(-12 if side < 0 else 7, yy, 10),
					Vector3i(-7 if side < 0 else 12, yy, 11))
	# Dark recessed spinal split, neck hinge and layered pectorals.
	p.fill_box(Vector3i(-1, -6, -8), Vector3i(0, 2, -7), 1)
	for y in [-5, -1]:
		p.carve_box(Vector3i(-8, y, -7), Vector3i(7, y, -7))
	p.fill_box(Vector3i(-5, -10, -3), Vector3i(4, -8, 4), 1)
	p.fill_box(Vector3i(-4, -10, -6), Vector3i(3, -9, -4), 8)
	# Atlas trademark skull is an actual three-dimensional helmet, not a box.
	ellipsoid(p, Vector3(-0.5, 7.8, -4.6), Vector3(6.0, 5.1, 5.0), 6, 8)
	# Pronounced bone brow, hollow eye sockets, luminous inset pupils.
	ellipsoid(p, Vector3(-0.5, 10.0, -7.0), Vector3(5.3, 2.0, 3.2), 6, 6)
	for eye in [-3, 2]:
		p.carve_box(Vector3i(eye - 1, 8, -11), Vector3i(eye + 1, 10, -8))
		p.fill_box(Vector3i(eye, 9, -8), Vector3i(eye, 9, -8), 7)
	# Sloping cheekbones, deep nasal cavity and separate lower jaw.
	for side in [-1, 1]:
		var x := -5 if side == -1 else 3
		ellipsoid(p, Vector3(float(x), 5.9, -7.4),
				Vector3(2.3, 2.1, 2.0), 6, 6)
	p.carve_box(Vector3i(-1, 5, -11), Vector3i(0, 7, -9))
	ellipsoid(p, Vector3(-0.5, 3.1, -6.8), Vector3(4.2, 1.7, 2.4), 6, 8)
	for x in [-3, -1, 1, 3]:
		p.fill_box(Vector3i(x, 3, -9), Vector3i(x, 4, -9), 6)
		p.carve_box(Vector3i(x - 1, 3, -9), Vector3i(x - 1, 3, -9))
	# Correctly distinctive Atlas torso loadout: five-feed LRM rack at left,
	# and a *bored* AC/20 port in the opposite torso.
	p.fill_box(Vector3i(-14, -2, -8), Vector3i(-7, 3, -6), 9)
	for x in [-13, -11, -9, -7]:
		for y in [-1, 1]:
			if x == -7 and y == -1:
				continue
			p.carve_box(Vector3i(x, y, -9), Vector3i(x, y, -7))
			p.fill_box(Vector3i(x, y, -6), Vector3i(x, y, -6), 3)
	tube(p, 9, -1, -12, -7, 3.2, 1.4, 8)
	# Torso-mounted equipment is more substantial than a colored face stripe.
	ellipsoid(p, Vector3(9, -1, -6), Vector3(4.0, 3.8, 3.5), 0)
	tube(p, 9, -1, -13, -7, 3.2, 1.4, 8)
	# A waist girdle with distinct mechanical pelvis plates.
	for side in [-1, 1]:
		ellipsoid(p, Vector3(float(side) * 3.8, -8.7, -1.0),
				Vector3(3.6, 2.1, 4.0), 0)
	p.fill_box(Vector3i(-1, -9, -5), Vector3i(0, -7, -5), 3)


static func _hunchback(p: VoxelPart) -> void:
	p.cells.clear()
	hull(p, -8, 3, Vector2(5.4, 5.0), Vector2(8.6, 6.1), 0)
	# Hunchback's silhouette is deliberately *uneven*: great right-shoulder
	# autocannon box vs tiny cockpit tucked into the left side.
	ellipsoid(p, Vector3(7.3, 5.7, 0), Vector3(6.2, 6.2, 5.8), 4)
	ellipsoid(p, Vector3(-7.8, 0.6, 1), Vector3(4.5, 4.8, 5.1), 0)
	ellipsoid(p, Vector3(-3.0, 5.7, -4.0), Vector3(3.8, 3.6, 3.9), 4)
	p.fill_box(Vector3i(-5, 5, -8), Vector3i(-2, 6, -7), 2)
	p.fill_box(Vector3i(-4, 7, -8), Vector3i(-3, 7, -7), 1)
	# Big chamfered ballistic shroud with a working *circular* muzzle.
	ellipsoid(p, Vector3(7.0, 6.5, -6.5), Vector3(5.7, 5.0, 5.8), 8)
	tube(p, 7, 6, -17, -6, 3.0, 1.5, 8)
	ring_x(p, 11, 15, 5, 1, 3.4, 1.8, 8)
	for z in [-12, -9, -6]:
		p.fill_box(Vector3i(4, 9, z), Vector3i(10, 9, z), 1)
	# Real inset rear sinks and separate hip girdle.
	for x in [-7, 2, 9]:
		ellipsoid(p, Vector3(float(x), 0, 7.4), Vector3(2.0, 4.0, 2.4), 8)
		for y in [-2, 0, 2]:
			p.carve_box(Vector3i(x - 1, y, 9), Vector3i(x + 1, y, 9))
	p.fill_box(Vector3i(10, 8, 2), Vector3i(13, 11, 4), 4)
	p.fill_box(Vector3i(-5, -10, -3), Vector3i(5, -9, 4), 1)


static func _wolverine(p: VoxelPart) -> void:
	p.cells.clear()
	hull(p, -8, 4, Vector2(4.6, 4.7), Vector2(10.7, 6.5), 0)
	for side in [-1, 1]:
		ellipsoid(p, Vector3(float(side) * 9.0, 3.2, 0.8),
				Vector3(4.6, 3.9, 6.4), 4)
	# Fast, sloping armored canopy with independent nose and brow.
	ellipsoid(p, Vector3(0, 5.0, -5.0), Vector3(4.4, 3.8, 5.4), 4)
	p.fill_box(Vector3i(-2, 5, -11), Vector3i(1, 6, -9), 2)
	p.fill_box(Vector3i(-1, 5, -12), Vector3i(0, 5, -11), 1)
	# Left shoulder six-pack; actual cylindrical voids, not blue squares.
	p.fill_box(Vector3i(-14, 0, -8), Vector3i(-8, 6, -6), 9)
	for x in [-13, -11, -9]:
		for y in [2, 5]:
			p.carve_box(Vector3i(x, y, -9), Vector3i(x, y, -6))
			p.fill_box(Vector3i(x, y, -5), Vector3i(x, y, -5), 3)
	# Chest is split into multiple angular removable armor plates.
	for side in [-1, 1]:
		for y in [-5, -2, 1]:
			p.fill_box(Vector3i(-8 if side < 0 else 1, y, -7),
					Vector3i(-2 if side < 0 else 7, y + 1, -6), 4)
	# Tall rear exhaust banks and an open mechanical waist.
	for x in [-7, -2, 4]:
		ellipsoid(p, Vector3(float(x), 0, 7.2), Vector3(2, 3.9, 3), 8)
		for y in [-2, 0, 2]:
			p.carve_box(Vector3i(x - 1, y, 9), Vector3i(x + 1, y, 9))
	p.fill_box(Vector3i(-5, -10, -2), Vector3i(4, -9, 3), 1)


static func _prototype(p: VoxelPart) -> void:
	p.cells.clear()
	# A visually distinct instrumented demonstrator rather than another box.
	hull(p, -8, 3, Vector2(4.7, 4.5), Vector2(9.8, 6.1), 0)
	for side in [-1, 1]:
		ellipsoid(p, Vector3(float(side) * 9.5, 2, 1),
				Vector3(4.5, 4.4, 5.4), 4)
		ellipsoid(p, Vector3(float(side) * 6.2, 0, 7.2),
				Vector3(2.2, 3.8, 2.8), 8)
	# The distinctive sloped dual sensor windscreen.
	ellipsoid(p, Vector3(0, 5.0, -5.7), Vector3(5.1, 3.5, 4.8), 4)
	p.fill_box(Vector3i(-4, 5, -10), Vector3i(3, 6, -9), 2)
	p.fill_box(Vector3i(-3, 1, -10), Vector3i(2, 3, -9), 2)
	p.fill_box(Vector3i(-1, 4, -11), Vector3i(0, 7, -9), 1)
	p.carve_box(Vector3i(-5, 3, 2), Vector3i(-5, 4, 3))
	for x in [-6, 5]:
		p.carve_box(Vector3i(x, 3, 3), Vector3i(x + 1, 5, 6))
		p.fill_box(Vector3i(x, 2, 3), Vector3i(x + 1, 2, 6), 1)
	# Rooftop mast with optical cap and split coolant radiators.
	p.fill_box(Vector3i(-1, 8, 1), Vector3i(0, 10, 2), 1)
	ellipsoid(p, Vector3(-0.5, 10.5, 1.5), Vector3(2, 1.5, 1.6), 2)
	for x in [-7, 5]:
		for y in [-3, 0, 3]:
			p.carve_box(Vector3i(x, y, 9), Vector3i(x + 1, y, 9))
	p.fill_box(Vector3i(-4, -9, -2), Vector3i(3, -8, 3), 1)


static func _catapult(p: VoxelPart) -> void:
	p.cells.clear()
	# Bird-like torso: pear-shaped reactor taper and lowered pointed beak.
	hull(p, -7, 3, Vector2(4.3, 4.7), Vector2(7.6, 6.2), 4, 2.2)
	ellipsoid(p, Vector3(0, 0, -8), Vector3(5.2, 3.7, 6.6), 4)
	ellipsoid(p, Vector3(0, 2.8, -9), Vector3(4.0, 2.7, 5.0), 2, 4)
	# Forward-swept beak with dark seam and side glazing.
	p.fill_box(Vector3i(-1, 1, -15), Vector3i(0, 2, -13), 2)
	p.fill_box(Vector3i(-1, 1, -15), Vector3i(-1, 3, -12), 1)
	for side in [-1, 1]:
		ellipsoid(p, Vector3(float(side) * 5.5, 1.7, 6.1),
				Vector3(3.0, 3.7, 4.2), 8)
		for y in [-1, 1, 3]:
			p.carve_box(Vector3i(-9 if side < 0 else 4, y, 10),
					Vector3i(-4 if side < 0 else 9, y, 10))
	p.fill_box(Vector3i(-3, -9, 0), Vector3i(2, -7, 4), 1)


static func _jenner(p: VoxelPart) -> void:
	# Retain its unusually long nose, wraparound glass and four SRM ports.
	# Break up the large squared rear engine deck with curved housings and
	# recessed radiator sides; the silhouette remains a light bird-like mech.
	for side in [-1, 1]:
		var x := -7 if side < 0 else 6
		ellipsoid(p, Vector3(float(x), 0.3, 5.2),
				Vector3(4.0, 2.6, 4.5), 4)
		for z in [3, 5, 7]:
			p.carve_box(Vector3i(-11 if side < 0 else 9, 1, z),
					Vector3i(-10 if side < 0 else 10, 1, z))
	# Reinforce the canopy's tapered cheek plates without squaring its nose.
	for side in [-1, 1]:
		var x := -4 if side < 0 else 3
		for z in range(-15, -9):
			var y := 0 if z < -12 else 1
			p.fill_box(Vector3i(x, y, z), Vector3i(x, y + 1, z), 8)
	# Pinned hip bearing and exposed rear heat exchange outlet.
	ellipsoid(p, Vector3(0, -5.0, 3.0), Vector3(4.0, 2.2, 4.5), 8)


static func arm(p: VoxelPart, shape: String, side: int) -> void:
	if shape == "jenner" or shape == "catapult":
		# Keep the Jenner's two separate laser bores and Catapult's 15
		# physically open LRM cells; contour their outer casings later.
		return
	p.cells.clear()
	var mass := 1.14 if shape == "atlas" else (0.96 if shape == "hunchback" else 0.86)
	ellipsoid(p, Vector3(0, -0.5, 0), Vector3(5.7 * mass, 3.9, 5.2), 4)
	ellipsoid(p, Vector3(0, -5.0, 0.2), Vector3(4.1 * mass, 6.2, 3.7), 0)
	ellipsoid(p, Vector3(0, -8.7, -1.8), Vector3(4.3 * mass, 3.3, 4.8), 8)
	# Exposed elbow cylinders and a forward articulated gauntlet.
	ring_x(p, -5, 5, -6, 0, 2.6, 1.3, 1)
	for x in [-3, 0, 3]:
		ellipsoid(p, Vector3(float(x), -11.1, -3.6),
				Vector3(1.35, 2.0, 2.0), 4, 8)
	for x in [-5, 4]:
		p.fill_box(Vector3i(x, -8, 2), Vector3i(x, -3, 3), 1)
	if shape == "atlas":
		# Symmetric armored fists, but not large yellow pistol boxes.
		tube(p, 0, -5, -13, -6, 2.7, 1.1, 8)
	elif shape == "wolverine" and side == 1:
		tube(p, 0, -6, -17, -7, 4.4, 1.1, 8)
	elif shape == "hunchback":
		if side == 1:
			# Weapon-side coaxial laser; the opposite arm is a plain fist.
			tube(p, 0, -6, -11, -6, 2.3, 0.8, 8)
		else:
			for x in [-3, 0, 3]:
				p.fill_box(Vector3i(x, -12, -5), Vector3i(x + 1, -11, -3), 4)
	elif shape == "prototype" and side == 0:
		tube(p, 0, -6, -12, -6, 4.5, 1.5, 8)


static func leg(p: VoxelPart, shape: String, segment: String) -> void:
	if shape == "jenner" or segment == "metatarsal":
		# Preserve Jenner's custom three-link IK geometry and joints.
		return
	p.cells.clear()
	var heavy := 1.18 if shape == "atlas" else (1.07 if shape == "hunchback" else 0.94)
	if shape == "catapult":
		heavy = 0.90
	match segment:
		"thigh":
			ellipsoid(p, Vector3(0, -4.0, 0.2),
					Vector3(4.5 * heavy, 5.8, 3.6), 0)
			ellipsoid(p, Vector3(0, -3.5, -3.0),
					Vector3(3.7 * heavy, 4.0, 2.6), 4)
			ring_x(p, -5, 5, -1, 0, 2.8, 1.3, 8)
			ring_x(p, -5, 5, -9, 0, 2.7, 1.1, 1)
			for x in [-4, 4]:
				p.fill_box(Vector3i(x, -7, 2), Vector3i(x, -3, 4), 8)
		"shin":
			ellipsoid(p, Vector3(0, -4.0, 0.4),
					Vector3(4.0 * heavy, 6.0, 3.3), 0)
			ellipsoid(p, Vector3(0, -6.1, -3.2),
					Vector3(3.9 * heavy, 3.7, 2.4), 4)
			ring_x(p, -5, 5, 0, 0, 2.7, 1.2, 1)
			for x in [-3, 3]:
				p.fill_box(Vector3i(x, -8, 3), Vector3i(x, -2, 4), 8)
				p.carve_box(Vector3i(x, -6, 3), Vector3i(x, -4, 3))
		"foot":
			ellipsoid(p, Vector3(0, -0.8, -2.0),
					Vector3(5.2 * heavy, 2.3, 8.4), 0)
			for x in [-4, 0, 4]:
				ellipsoid(p, Vector3(float(x), -1.5, -10.3),
						Vector3(1.4, 1.4, 3.3), 4)
			# Real negative space between separate toe end plates.
			for x in [-2, 2]:
				p.carve_box(Vector3i(x, -2, -14),
						Vector3i(x, -1, -10))
			ellipsoid(p, Vector3(0, 0, 4), Vector3(4.5, 1.3, 3), 8)


## At 25-37.5 mm, remove only unsupported three-face corner microvoxels.
## This is an actual geometric bevel and changes the exposed silhouette.
## Work on a snapshot, never modify the dictionary during iteration.
static func micro_bevel(p: VoxelPart) -> void:
	if p.detail_scale < 2:
		return
	var remove: Array[Vector3i] = []
	for cell: Vector3i in p.cells:
		var material: int = p.cells[cell]
		if material == 1 or material == 2 or material == 3 or material == 7:
			continue
		var exposed_axes := 0
		if not p.cells.has(cell + Vector3i.RIGHT) or not p.cells.has(cell + Vector3i.LEFT):
			exposed_axes += 1
		if not p.cells.has(cell + Vector3i.UP) or not p.cells.has(cell + Vector3i.DOWN):
			exposed_axes += 1
		if not p.cells.has(cell + Vector3i.BACK) or not p.cells.has(cell + Vector3i.FORWARD):
			exposed_axes += 1
		if exposed_axes == 3:
			remove.append(cell)
	for cell in remove:
		p.cells.erase(cell)
