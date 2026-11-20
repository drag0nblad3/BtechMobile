class_name VoxelReferenceV4
extends RefCounted
## CLEAN-SLATE VISUAL SCULPTS based on two art traditions per production chassis:
## CGL contemporary Technical Readout/miniature and original TRO:3025 art.
## See docs/graphics/reference-v4-proportion-sheet.md for visual landmarks.
##
## Parts are explicitly authored on a 75 mm local lattice, then physically
## divided into 37.5 or 25 mm damage voxels. Never call V2/V3 sculptors.
## -Z is forward; Y up. Joints and game rules remain independent.


## Beveled, filled armor cross-section. Rounded corners via chamfer, not
## repeated spheres. The shell is backed by a real dark frame.
static func section(p: VoxelPart, y: int, cx: float, cz: float,
		rx: float, rz: float, armor: int = 0, core: int = 1,
		chamfer: float = 0.24) -> void:
	for x in range(floori(cx - rx), ceili(cx + rx) + 1):
		for z in range(floori(cz - rz), ceili(cz + rz) + 1):
			var ax := absf((float(x) - cx) / maxf(0.1, rx))
			var az := absf((float(z) - cz) / maxf(0.1, rz))
			var d := maxf(ax, az) + minf(ax, az) * chamfer
			if d <= 1.0:
				p.cells[Vector3i(x, y, z)] = armor if d > 0.74 else core


static func tapered(p: VoxelPart, y0: int, y1: int,
		lower: Vector3, upper: Vector3, material: int = 0,
		chamfer: float = 0.24, center_x: float = 0.0) -> void:
	for y in range(y0, y1 + 1):
		var t := float(y - y0) / maxf(1.0, float(y1 - y0))
		var widths := lower.lerp(upper, t)
		section(p, y, center_x, widths.z, widths.x, widths.y,
				material, 1, chamfer)


## A real cylindrical tube facing -Z; erase its center all along the bore.
static func barrel(p: VoxelPart, cx: int, cy: int, z0: int, z1: int,
		radius: float, bore: float, armor: int = 8) -> void:
	for z in range(z0, z1 + 1):
		for x in range(cx - ceili(radius), cx + ceili(radius) + 1):
			for y in range(cy - ceili(radius), cy + ceili(radius) + 1):
				var d := Vector2(float(x - cx), float(y - cy)).length()
				var c := Vector3i(x, y, z)
				if d <= bore:
					p.cells.erase(c)
				elif d <= radius:
					p.cells[c] = armor


## Perpendicular mechanical hub: real side-exposed annulus centered on a
## hinge, not a bulbous armored globe glued onto each limb.
static func hub(p: VoxelPart, cy: int, cz: int,
		x0: int, x1: int, radius: float, hole: float = 0.6) -> void:
	for x in range(x0, x1 + 1):
		for y in range(cy - ceili(radius), cy + ceili(radius) + 1):
			for z in range(cz - ceili(radius), cz + ceili(radius) + 1):
				var d := Vector2(float(y - cy), float(z - cz)).length()
				if d <= radius and d > hole:
					p.cells[Vector3i(x, y, z)] = 8


## Angled strut between endpoints. A real, thin material connection.
static func rod(p: VoxelPart, start: Vector3i, finish: Vector3i,
		radius: float, material: int = 8) -> void:
	var a := Vector3(start)
	var b := Vector3(finish)
	var delta := b - a
	var length2 := maxf(0.01, delta.length_squared())
	var r := ceili(radius)
	for x in range(mini(start.x, finish.x) - r, maxi(start.x, finish.x) + r + 1):
		for y in range(mini(start.y, finish.y) - r, maxi(start.y, finish.y) + r + 1):
			for z in range(mini(start.z, finish.z) - r, maxi(start.z, finish.z) + r + 1):
				var q := Vector3(x, y, z)
				var t := clampf((q - a).dot(delta) / length2, 0.0, 1.0)
				if q.distance_squared_to(a + delta * t) <= radius * radius:
					p.cells[Vector3i(x, y, z)] = material


## Box with four progressively clipped armor corners (no solid prisms with
## square vertical silhouette), can have an exposed core or an open chamber.
static func faceted_box(p: VoxelPart, low: Vector3i, high: Vector3i,
		material: int, bevel: int = 2) -> void:
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			for z in range(low.z, high.z + 1):
				var corner := mini(x - low.x, high.x - x) + mini(z - low.z, high.z - z)
				if corner >= bevel:
					p.cells[Vector3i(x, y, z)] = material


static func torso(p: VoxelPart, shape: String) -> void:
	p.cells.clear()
	match shape:
		"atlas":
			_atlas(p)
		"hunchback":
			_hunchback(p)
		"wolverine":
			_wolverine(p)
		"jenner":
			_jenner(p)
		"catapult":
			_catapult(p)
		_:
			_prototype(p)


static func _atlas(p: VoxelPart) -> void:
	# Reference: low, integrated death's head above a deep flat-sided chest.
	# Narrow *pelvis*, broad shoulder girdle. No round football pectorals.
	tapered(p, -9, 5, Vector3(5.0, 4.0, 1),
			Vector3(9.1, 5.4, 0), 0, 0.27)
	tapered(p, -11, -8, Vector3(4.0, 3.0, 1),
			Vector3(5.0, 4.0, 1), 8)
	# Distinct left and right broad faceted shoulder assemblies with open
	# mechanical shoulders, instead of spheres along a horizontal T bar.
	for side in [-1, 1]:
		var cx := float(side) * 10.4
		for y in range(0, 9):
			var w := 3.8 if y < 5 else (3.3 if y < 7 else 2.5)
			section(p, y, cx, 0.0, w, 4.2, 4, 1, 0.38)
		var sx := -14 if side < 0 else 13
		hub(p, 0, 1, sx, sx + 2, 2.5, 0.7)
		# Segmented, slanted torso pectorals, left/right do not blend into
		# one giant cuboid. The seam is a true exposed cavity.
		for y in range(-5, 3):
			var xx := -5 if side < 0 else 2
			var back := -7 if y < -1 else -8
			p.fill_box(Vector3i(xx, y, back),
					Vector3i(xx + 3, y, back + 1), 4)
		# Dorsal power block and three *open* vent slits.
		var rx := -9 if side < 0 else 6
		faceted_box(p, Vector3i(rx, 0, 5),
				Vector3i(rx + 3, 6, 9), 8, 2)
		for vy in [1, 3, 5]:
			p.carve_box(Vector3i(rx, vy, 9),
					Vector3i(rx + 3, vy, 9))
	# Skull itself is SMALL compared to shoulder span (8 cells vs 28).
	# Armored chin joins a visibly narrow reinforced neck at y 4..6.
	rod(p, Vector3i(0, 3, -2), Vector3i(0, 5, -3), 2.1, 8)
	for y in range(5, 12):
		var width := 3.7 if y < 9 else (3.1 if y < 11 else 2.5)
		var center_z := -3.7 if y < 9 else -3.2
		section(p, y, -0.5, center_z, width, 3.3, 6, 8, 0.39)
	# Bone plates and a true projecting eyebrow (not a giant flat helmet).
	p.fill_box(Vector3i(-4, 9, -7), Vector3i(3, 10, -6), 6)
	for eye in [-2, 1]:
		p.carve_box(Vector3i(eye - 1, 7, -8),
				Vector3i(eye + 1, 8, -6))
		p.fill_box(Vector3i(eye, 8, -6), Vector3i(eye, 8, -6), 7)
	# Separate cheekbones, nose bridge and gritted lower jaw.
	for side in [-1, 1]:
		var xx := -4 if side < 0 else 2
		p.fill_box(Vector3i(xx, 5, -7), Vector3i(xx + 1, 7, -6), 6)
	p.carve_box(Vector3i(-1, 5, -8), Vector3i(0, 6, -6))
	p.fill_box(Vector3i(-3, 4, -6), Vector3i(2, 5, -5), 6)
	for x in [-2, 0, 2]:
		p.fill_box(Vector3i(x, 4, -7), Vector3i(x, 4, -7), 8)
	# Weapons mounted into the massive torso, and NOT in both hands.
	# AC/20 exposed on the right front, thick bored sleeve.
	barrel(p, 7, -1, -12, -5, 2.7, 1.2, 8)
	# Left torso launcher: 5 exit apertures, four salvo reloads inside.
	faceted_box(p, Vector3i(-10, -3, -9),
			Vector3i(-4, 3, -6), 4, 1)
	for x in [-9, -7, -5]:
		for y in [-1, 1]:
			if x == -5 and y == -1:
				continue
			p.carve_box(Vector3i(x, y, -10), Vector3i(x, y, -6))
			p.fill_box(Vector3i(x, y, -5), Vector3i(x, y, -5), 3)
	# Angular front apron prevents a floating chest-over-legs silhouette.
	faceted_box(p, Vector3i(-4, -11, -5), Vector3i(3, -8, -3), 4, 1)


static func _hunchback(p: VoxelPart) -> void:
	# Small torso and an enormous high RIGHT-SHOULDER AC/20 body: reference
	# identity is 80% that asymmetric silhouette.
	tapered(p, -9, 4, Vector3(4.8, 3.5, 0),
			Vector3(7.2, 4.8, 0), 0, 0.27)
	# Compact cockpit shifted LEFT and sunken below the cannon housing.
	tapered(p, 4, 10, Vector3(3.0, 3.1, -2),
			Vector3(2.2, 2.7, -2), 4, 0.30, -3.5)
	p.fill_box(Vector3i(-5, 7, -6), Vector3i(-3, 9, -6), 2)
	p.fill_box(Vector3i(-4, 8, -7), Vector3i(-4, 8, -7), 1)
	# Cannon tower high on right: chamfered rectangular broad vertical plate.
	faceted_box(p, Vector3i(2, 3, -5),
			Vector3i(13, 12, 6), 4, 2)
	p.fill_box(Vector3i(3, 11, -3), Vector3i(12, 12, 4), 8)
	# Recoil carriage front is square, with circular 20cm bore.
	faceted_box(p, Vector3i(4, 7, -10),
			Vector3i(11, 12, -5), 8, 1)
	barrel(p, 8, 9, -17, -7, 3.0, 1.4, 8)
	# Ammunition-feed ribbing and exposed cooling machinery on outboard side.
	for y in [4, 6, 8, 10]:
		p.carve_box(Vector3i(13, y, -1),
				Vector3i(13, y, 5))
		p.fill_box(Vector3i(12, y, 0),
				Vector3i(12, y, 4), 8)
	# Modest left shoulder; left must not replicate the tower.
	faceted_box(p, Vector3i(-10, -1, -3),
			Vector3i(-7, 5, 4), 0, 2)
	# Short pelvis and exposed circular torso swivel.
	p.fill_box(Vector3i(-4, -11, -2), Vector3i(4, -9, 3), 8)
	p.fill_box(Vector3i(-3, -12, -4), Vector3i(3, -11, 0), 0)


static func _wolverine(p: VoxelPart) -> void:
	# Taller, slim medium humanoid with very distinctive UPRIGHT cockpit.
	tapered(p, -9, 5, Vector3(3.9, 3.2, 0.5),
			Vector3(7.6, 4.0, 0.0), 0, 0.30)
	for side in [-1, 1]:
		var x := -9 if side < 0 else 6
		faceted_box(p, Vector3i(x, 1, -4),
				Vector3i(x + 3, 6, 4), 4, 1)
	# Tall faceted helmet with peaked brow and thin glass windscreen.
	tapered(p, 5, 14, Vector3(2.8, 3.0, -2),
			Vector3(2.1, 2.6, -2), 4, 0.31)
	p.fill_box(Vector3i(-2, 8, -6), Vector3i(1, 11, -6), 2)
	p.fill_box(Vector3i(-1, 8, -7), Vector3i(-1, 11, -6), 1)
	p.fill_box(Vector3i(-3, 12, -5), Vector3i(2, 13, -4), 8)
	for x in [-3, 2]:
		rod(p, Vector3i(x, 13, 0), Vector3i(x, 16, 1), 0.8, 8)
	# SIX separate missile tubes high on the left shoulder, not hidden in
	# a giant Atlas-size chest plate.
	faceted_box(p, Vector3i(-12, 5, -9),
			Vector3i(-7, 12, -5), 9, 1)
	for x in [-11, -9, -7]:
		for y in [7, 10]:
			p.carve_box(Vector3i(x, y, -10),
					Vector3i(x, y, -6))
			p.fill_box(Vector3i(x, y, -5),
					Vector3i(x, y, -5), 3)
	# Sternum with sloped separate armor, NOT a wide slab.
	for y in range(-6, 3):
		var w := 2 if y < -3 else 3
		p.fill_box(Vector3i(-w, y, -5),
				Vector3i(w, y, -5), 4)
	p.fill_box(Vector3i(-3, -11, -3), Vector3i(3, -9, 2), 8)
	# Slim right-hand rear jump-jet backpack. Separate vanes are tangible
	# armor behind the cockpit rather than a larger bland torso shell.
	faceted_box(p, Vector3i(4, 3, 4), Vector3i(9, 10, 9), 8, 1)
	for y in [5, 7, 9]:
		p.carve_box(Vector3i(4, y, 9), Vector3i(9, y, 9))
	for x in [5, 7]:
		rod(p, Vector3i(x, 1, 4), Vector3i(x, 10, 7), 0.8, 4)


static func _jenner(p: VoxelPart) -> void:
	# Aircraft fuselage, not a human torso with a head. Its long projecting
	# nose is the signature, cockpit low under a raised SRM-4 battery.
	for z in range(-25, 11):
		var t := clampf(float(z + 25) / 35.0, 0.0, 1.0)
		var half_x := lerpf(1.2, 5.8, t)
		var half_y := lerpf(1.1, 3.4, t)
		for y in range(-ceili(half_y), ceili(half_y) + 1):
			var front := -0.4 if z < -14 else (0.0 if z < 0 else -0.7)
			var w := half_x * (1.0 - 0.17 * absf(float(y) - front) / half_y)
			for x in range(-ceili(w), ceili(w) + 1):
				if absf(float(x)) > w:
					continue
				p.cells[Vector3i(x, y, z)] = 4
	# Glass lives high on the small wedge forward of the shoulder hardware.
	for z in range(-21, -11):
		var w := 1 if z < -18 else (2 if z < -15 else 3)
		p.fill_box(Vector3i(-w, 1, z), Vector3i(w - 1, 1, z), 2)
		p.fill_box(Vector3i(-1, 1, z), Vector3i(-1, 1, z), 1)
	# Enlarged thrust fairings aft, separate open radiators not bulbous arms.
	for side in [-1, 1]:
		var xc := float(side) * 7.0
		for z in range(0, 12):
			var taper := 2.5 if z < 8 else 1.8
			for y in range(-2, 4):
				for x in range(floori(xc - taper), ceili(xc + taper) + 1):
					if absf(float(x) - xc) <= taper:
						p.cells[Vector3i(x, y, z)] = 0 if y == 3 else 4
		var xx := -9 if side < 0 else 8
		for yy in [-1, 1]:
			p.carve_box(Vector3i(xx, yy, 10),
					Vector3i(xx + 1, yy, 11))
	# Exposed intake lips along dorsal SRM-4 four-portal launcher.
	faceted_box(p, Vector3i(-4, 4, -5),
			Vector3i(3, 8, -2), 8, 1)
	for x in [-2, 1]:
		for y in [5, 7]:
			p.carve_box(Vector3i(x, y, -6),
					Vector3i(x, y, -2))
			p.fill_box(Vector3i(x, y, -1), Vector3i(x, y, -1), 3)
	# Lightweight exposed pelvis rails, not a giant dark belly.
	rod(p, Vector3i(-4, -4, 0), Vector3i(-5, -8, 2), 1.2, 8)
	rod(p, Vector3i(3, -4, 0), Vector3i(4, -8, 2), 1.2, 8)


static func _catapult(p: VoxelPart) -> void:
	# A VERY NARROW horizontal bird fuselage with a sharp nose that is
	# visibly smaller than the TALL rocket towers on either flank.
	for z in range(-19, 11):
		var ratio := clampf(float(z + 19) / 28.0, 0.0, 1.0)
		var radius_x := lerpf(1.0, 4.7, ratio)
		var radius_y := lerpf(1.0, 3.6, ratio)
		for y in range(-ceili(radius_y), ceili(radius_y) + 1):
			var local_r := radius_x * (1.0 - 0.24 * absf(float(y)) / radius_y)
			for x in range(-ceili(local_r), ceili(local_r) + 1):
				if absf(float(x)) <= local_r:
					p.cells[Vector3i(x, y, z)] = 4 if absf(float(y)) > 1 else 0
	# Short glass canopy, narrow wedge rather than broad cyan face.
	for z in range(-16, -8):
		var w := 1 if z < -13 else 2
		p.fill_box(Vector3i(-w, 1, z),
				Vector3i(w, 2, z), 2)
	p.fill_box(Vector3i(-1, 2, -15), Vector3i(-1, 2, -10), 1)
	# Open side turbine ducts rear of the cockpit.
	for side in [-1, 1]:
		var xx := -6 if side < 0 else 5
		faceted_box(p, Vector3i(xx, -2, 5),
				Vector3i(xx + 2, 3, 11), 8, 1)
		for yy in [-1, 1]:
			p.carve_box(Vector3i(xx, yy, 11),
					Vector3i(xx + 2, yy, 11))
	# Thin waist under broad engine; note NO humanoid breastplate.
	for x in [-3, 3]:
		rod(p, Vector3i(x, -3, 1), Vector3i(x, -8, 1), 1.2, 8)


static func _prototype(p: VoxelPart) -> void:
	# NONCANONICAL mechanics-test chassis; deliberately not another Atlas.
	# Inspiration: cockpit scale and joint layout from Locust/Crab workshop
	# mechs, with an exposed spine and asymmetric survey equipment.
	tapered(p, -9, 5, Vector3(3.0, 3.2, 1),
			Vector3(5.5, 3.7, 0), 0, 0.40)
	faceted_box(p, Vector3i(-3, 5, -6),
			Vector3i(3, 12, 0), 4, 2)
	p.fill_box(Vector3i(-2, 8, -7), Vector3i(1, 10, -7), 2)
	p.fill_box(Vector3i(-1, 7, -8), Vector3i(-1, 11, -7), 1)
	rod(p, Vector3i(4, 8, 1), Vector3i(5, 19, 2), 0.6, 8)
	faceted_box(p, Vector3i(4, 17, 1),
			Vector3i(6, 20, 4), 8, 1)
	for side in [-1, 1]:
		var xx := -7 if side < 0 else 5
		hub(p, 3, 1, xx, xx + 1, 2.3, 0.8)
	# One asymmetric high rear radiator; visibly different from the Atlas.
	faceted_box(p, Vector3i(-7, 1, 4),
			Vector3i(-4, 9, 8), 8, 1)
	for yy in [2, 4, 6, 8]:
		p.carve_box(Vector3i(-7, yy, 8),
				Vector3i(-4, yy, 8))
	# Tall open-frame instrument/heat-transfer equipment. These are
	# independently shaped cooling fins, struts and replaceable modules,
	# not bulk filled merely to hit a voxel-count threshold.
	for x in [-8, -6, -4, 4, 6, 8]:
		for y in range(-1, 12):
			var rear := 5 if x < 0 else 4
			for z in range(rear, rear + 4):
				var top_slope := (y > 8 and z > rear + 1)
				if not top_slope:
					p.cells[Vector3i(x, y, z)] = 8 if y % 3 == 0 else 4
		for vy in [0, 3, 6, 9]:
			p.carve_box(Vector3i(x, vy, 7),
					Vector3i(x, vy, 8))
	for x in [-7, 5]:
		rod(p, Vector3i(x, -6, 5),
				Vector3i(x, 10, 8), 1.0, 8)
	# Independent left sensor barrel and right open cooling reel.
	barrel(p, -6, 7, -10, -4, 1.8, 0.7, 8)
	hub(p, 5, 7, 6, 10, 2.5, 1.2)


## Limb constructors are also independent: no shared "round upper arm /
## tree-trunk shin" generator. Each design gives individual segments their
## own taper, armor break points, visible axles and front/rear silhouette.
static func arm(p: VoxelPart, shape: String, side: int) -> void:
	p.cells.clear()
	match shape:
		"atlas":
			_atlas_arm(p, side)
		"hunchback":
			_hunchback_arm(p, side)
		"wolverine":
			_wolverine_arm(p, side)
		"jenner":
			_jenner_lasers(p, side)
		"catapult":
			_catapult_pod(p, side)
		_:
			_prototype_arm(p, side)


static func _atlas_arm(p: VoxelPart, side: int) -> void:
	# A long armored bicep, visibly slimmer exposed elbow, and large
	# segmented hands. In reference art the weapon is TORSO mounted.
	for y in range(-12, 3):
		var rx := 4.1 if y > -2 else (
				2.8 if y > -8 else 3.2)
		var rz := 3.3 if y > -2 else (2.0 if y > -8 else 2.5)
		section(p, y, 0, 0.0, rx, rz, 4 if y > -3 else 0)
	hub(p, -6, 0, -4, 4, 2.1, 0.8)
	# Separate forearm shields wrap the exposed elbow, not solid columns.
	for side_x in [-1, 1]:
		var xx := -4 if side_x < 0 else 3
		rod(p, Vector3i(xx, -8, 2), Vector3i(xx, -3, 2), 0.9, 8)
	# Five individually articulated finger blocks; no square hammerheads.
	for x in [-3, -1, 1, 3]:
		p.fill_box(Vector3i(x, -14, -2), Vector3i(x, -12, 0), 4)
		p.fill_box(Vector3i(x, -15, -1), Vector3i(x, -15, -1), 8)
	# One torso-matching armor plate over the knuckles.
	p.fill_box(Vector3i(-3, -11, -4), Vector3i(3, -9, -3), 4)
	if side == 1:
		# Small hand-mounted laser, not a second AC20 cannon.
		barrel(p, 1, -9, -8, -3, 1.5, 0.6, 8)
	else:
		rod(p, Vector3i(-3, -12, 1),
				Vector3i(-5, -11, -2), 1.0, 8)


static func _hunchback_arm(p: VoxelPart, side: int) -> void:
	# Compact brawler manipulator, intentionally dwarfed by AC20 tower.
	for y in range(-10, 3):
		var rx := 2.8 if y > -2 else (1.9 if y > -6 else 2.7)
		var z := 0.7 if y < -6 else 0.0
		section(p, y, 0, z, rx, 2.5, 0, 1, 0.35)
	hub(p, -5, 1, -3, 3, 1.8, 0.6)
	if side == 1:
		# Coaxial medium laser is small compared to shoulder autocannon.
		barrel(p, 0, -7, -9, -4, 1.4, 0.5, 8)
	else:
		for x in [-2, 0, 2]:
			p.fill_box(Vector3i(x, -12, -2),
					Vector3i(x, -10, 0), 8)
		rod(p, Vector3i(3, -9, 1), Vector3i(4, -11, -2), 0.8, 8)


static func _wolverine_arm(p: VoxelPart, side: int) -> void:
	# Slimmer humanoid upper arm and pronounced separate elbow hinge.
	for y in range(-13, 3):
		var rx := 3.0 if y > -2 else (2.0 if y > -7 else 2.5)
		var rz := 2.6 if y > -2 else 2.0
		section(p, y, 0, 0, rx, rz, 0 if y < -7 else 4)
	hub(p, -7, 0, -3, 3, 1.9, 0.7)
	rod(p, Vector3i(-3, -9, 2), Vector3i(-3, -3, 2), 0.8, 8)
	if side == 1:
		# One projecting right-arm AC/5 bore. Slim barrel, long sleeve.
		barrel(p, 0, -8, -17, -5, 2.1, 0.9, 8)
		barrel(p, 0, -8, -11, -7, 2.7, 1.0, 4)
	else:
		for x in [-2, 0, 2]:
			p.fill_box(Vector3i(x, -15, -2),
					Vector3i(x, -13, -1), 4)
		rod(p, Vector3i(3, -11, -1), Vector3i(4, -14, -3), 0.8)


static func _jenner_lasers(p: VoxelPart, side: int) -> void:
	# Two laser pods mounted directly on opposite sides of the fuselage,
	# NOT humanoid arms. Each forward tube is a separate bored housing.
	for y in range(-4, 5):
		var width := 3.4 if y in [-3, -2, 1, 2] else 2.5
		section(p, y, 0, 0, width, 4.4, 0, 1, 0.40)
	for y in [-2, 2]:
		# Each is forward pointing and physically hollow; do NOT place a
		# cyan painted cap over an empty barrel.
		barrel(p, 0, y, -12, -3, 2.0, 0.7, 8)
		p.fill_box(Vector3i(-1, y, -2),
				Vector3i(0, y, -2), 2)
	# Open interbarrel air gap, distinct upper and lower laser assemblies.
	p.carve_box(Vector3i(-2, 0, -12),
			Vector3i(2, 0, -6))
	# Swept heat shields behind each laser tube.
	for z in range(1, 8):
		var w := 3 if z < 4 else 2
		p.fill_box(Vector3i(-w, 3, z),
				Vector3i(w, 3, z), 4)
	for x in [-4, 4]:
		rod(p, Vector3i(x, -2, 2), Vector3i(x, 2, 6), 0.8, 8)


static func _catapult_pod(p: VoxelPart, side: int) -> void:
	# Distinct TALL LRM-15 housings at either side of a much smaller beak.
	# Rather than a fat cuboid hanging like an arm, the weapon rises above
	# the fuselage and is narrow in depth. Its X-braced hatch is outlined.
	for y in range(-5, 15):
		var half_x := 4.6 if y < 10 else (4.2 if y < 13 else 3.6)
		var half_z := 5.0 if y < 9 else 4.5
		section(p, y, 0.0, -1.0, half_x, half_z, 4, 1, 0.42)
	# Collar to mechanical shoulder axis.
	hub(p, -3, 0, -5, 5, 2.9, 0.9)
	p.fill_box(Vector3i(-4, 11, -6),
			Vector3i(4, 12, -5), 8)
	# Fifteen actual launcher openings, five columns and three rows, on
	# the front face, with rear recesses.
	for col in 5:
		var xx := -4 + col * 2
		for row in 3:
			var yy := 0 + row * 3
			p.fill_box(Vector3i(xx, yy, -7),
					Vector3i(xx, yy, -6), 8)
			p.carve_box(Vector3i(xx, yy, -9),
					Vector3i(xx, yy, -5))
			p.fill_box(Vector3i(xx, yy, -4),
					Vector3i(xx, yy, -4), 3)
	# Top access door with raised diagonal hinge; open right and left
	# flank heat sinks. Each pod has an independent side radiator.
	for x in [-3, 3]:
		rod(p, Vector3i(x, 13, -3),
				Vector3i(-x, 13, 2), 0.7, 8)
	var outside := -5 if side == 0 else 5
	for y in [-1, 2, 5]:
		p.carve_box(Vector3i(outside, y, 1),
				Vector3i(outside, y, 4))


static func _prototype_arm(p: VoxelPart, side: int) -> void:
	# Engineering test rig: left is a sampling cannon, right a claw.
	for y in range(-11, 3):
		var w := 2.6 if y > -3 else 1.8
		section(p, y, 0, 0, w, 2.4, 4, 1, 0.45)
	hub(p, -6, 0, -3, 3, 2.0, 0.7)
	if side == 0:
		barrel(p, 0, -8, -15, -6, 2.5, 1.0, 8)
	else:
		rod(p, Vector3i(-2, -10, -2),
				Vector3i(-4, -15, -6), 1.0, 8)
		rod(p, Vector3i(2, -10, -2),
				Vector3i(4, -15, -6), 1.0, 8)
		rod(p, Vector3i(0, -10, -3),
				Vector3i(0, -15, -7), 0.8, 8)


## Limb segment names and sockets are unchanged to preserve damage regions,
## stress test hit selection, and the tested two/three-link gait hierarchy.
static func leg(p: VoxelPart, shape: String, segment: String) -> void:
	p.cells.clear()
	if shape == "jenner":
		_jenner_leg(p, segment)
	elif shape == "catapult":
		_catapult_leg(p, segment)
	else:
		_humanoid_leg(p, shape, segment)


static func _humanoid_leg(p: VoxelPart, shape: String, segment: String) -> void:
	# TRIM AND LONG. Each actual calf is 4–6 coarse cells wide and
	# approximately 10 cells long, NOT the previous 12-cell round column.
	var w := 3.8 if shape == "atlas" else (
			3.3 if shape == "hunchback" else (
			2.6 if shape == "wolverine" else 2.3))
	match segment:
		"thigh":
			for y in range(-10, 2):
				var t := float(-y) / 10.0
				var r := lerpf(w + 0.25, w * 0.70, t)
				var zc := -0.45 * t
				section(p, y, 0, zc, r, 2.7, 0, 1, 0.36)
			# Knee shield is distinctly independent and separated from
			# the hip cap by a narrow narrowing mid-thigh.
			hub(p, -9, 0, -ceili(w), ceili(w), 2.0, 0.7)
			for y in [-9, -8]:
				p.fill_box(Vector3i(-2, y, -4),
						Vector3i(2, y, -3), 4)
			# Hollow side slots reveal load-bearing piston linkages.
			for x in [-ceili(w), ceili(w)]:
				p.carve_box(Vector3i(x, -7, 0),
						Vector3i(x, -4, 1))
			rod(p, Vector3i(0, 0, 3), Vector3i(0, -9, 3), 0.9)
		"shin":
			for y in range(-10, 2):
				var t := float(-y) / 10.0
				var r := lerpf(w * 0.66, w * 0.74, t)
				section(p, y, 0, 0.4, r, 2.2, 0, 1, 0.39)
			hub(p, 0, 0, -3, 3, 2.1, 0.7)
			# Raised tibia blade and *two* externally exposed pistons.
			for y in range(-8, -1):
				var r := 1 if y < -6 else 2
				p.fill_box(Vector3i(-r, y, -3),
						Vector3i(r, y, -3), 4)
			for x in [-3, 3]:
				rod(p, Vector3i(x, -2, 2),
						Vector3i(x, -9, 2), 0.6, 8)
			# True lateral cutout, not painted black patches.
			p.carve_box(Vector3i(-3, -6, 0), Vector3i(-3, -4, 0))
			p.carve_box(Vector3i(3, -6, 0), Vector3i(3, -4, 0))
			p.fill_box(Vector3i(-1, -10, -1), Vector3i(1, -9, 1), 8)
		"foot":
			# Slim long armored boots, with individual toe fingers and a
			# clearly distinct ankle/heel; not huge toboggan snowshoes.
			for y in range(-2, 2):
				section(p, y, 0, -2, w + 0.6, 4.8, 4, 1, 0.40)
			for x in [-3, 0, 3]:
				p.fill_box(Vector3i(x, -2, -10),
						Vector3i(x + 1, -1, -5), 4)
				p.fill_box(Vector3i(x, -2, -11),
						Vector3i(x, -2, -11), 8)
			for x in [-2, 2]:
				p.carve_box(Vector3i(x, -2, -11),
						Vector3i(x, -1, -7))
			rod(p, Vector3i(0, 1, 2), Vector3i(0, 0, 5), 1.2)


static func _jenner_leg(p: VoxelPart, segment: String) -> void:
	# Chicken walker anatomy: visible THIN actuator link between massive
	# hip rotor and backward hock, not continuous plated tree-trunk.
	match segment:
		"thigh":
			hub(p, -1, 0, -5, 5, 3.0, 1.2)
			rod(p, Vector3i(0, 0, 0),
					Vector3i(0, -11, -1), 1.8, 8)
			for y in range(-10, -2):
				var r := 2.8 if y > -6 else 2.3
				section(p, y, 0, -2.2, r, 1.6, 4, 1, 0.45)
			hub(p, -10, 0, -4, 4, 2.4, 1.0)
			rod(p, Vector3i(3, -3, 2),
					Vector3i(3, -9, 2), 0.7)
		"shin":
			hub(p, 0, 0, -4, 4, 2.5, 1.0)
			rod(p, Vector3i(0, 0, 0),
					Vector3i(0, -11, 1), 1.6, 8)
			for y in range(-10, -2):
				section(p, y, 0, -1.2, 2.1, 1.9, 0, 1, 0.45)
			rod(p, Vector3i(-3, -2, 2),
					Vector3i(-3, -10, 2), 0.65)
		"metatarsal":
			hub(p, 0, 0, -4, 4, 2.3, 0.9)
			rod(p, Vector3i(0, 0, 0),
					Vector3i(0, -5, 0), 1.4, 8)
			for x in [-2, 2]:
				rod(p, Vector3i(x, -1, 1),
						Vector3i(x, -5, -1), 0.7, 4)
		"foot":
			p.fill_box(Vector3i(-3, -1, -4),
					Vector3i(3, 0, 3), 4)
			for x in [-3, 0, 3]:
				rod(p, Vector3i(x, -1, -4),
						Vector3i(x, -2, -13), 1.0, 4)
				p.fill_box(Vector3i(x, -2, -14),
						Vector3i(x, -2, -14), 8)
			for x in [-2, 2]:
				p.carve_box(Vector3i(x, -2, -13),
						Vector3i(x, -1, -6))
			rod(p, Vector3i(0, 0, 3), Vector3i(0, -1, 6), 1.0, 8)


static func _catapult_leg(p: VoxelPart, segment: String) -> void:
	# Angular avian legs with exposed connectors; almost no enclosing
	# rectangular casing. Catapult is 65 tons but has strikingly light
	# below-knee silhouette in both classic and current references.
	match segment:
		"thigh":
			hub(p, -1, 0, -5, 5, 3.0, 1.0)
			rod(p, Vector3i(0, 0, 0),
					Vector3i(0, -10, -2), 1.7, 8)
			for y in range(-8, -2):
				section(p, y, 0, -2, 2.8, 1.8, 4, 1, 0.48)
			hub(p, -10, -1, -4, 4, 2.1, 0.9)
		"shin":
			hub(p, 0, 0, -4, 4, 2.1, 0.8)
			rod(p, Vector3i(0, 0, 0),
					Vector3i(0, -10, 1), 1.5, 8)
			for y in range(-8, -2):
				section(p, y, 0, 0, 2.0, 1.6, 4, 1, 0.48)
			rod(p, Vector3i(3, -1, 1),
					Vector3i(3, -9, 3), 0.7)
		"metatarsal":
			hub(p, 0, 0, -3, 3, 2.1, 0.7)
			for x in [-2, 2]:
				rod(p, Vector3i(x, 0, 0),
						Vector3i(x, -5, -2), 0.75, 8)
			rod(p, Vector3i(0, 0, -1),
					Vector3i(0, -5, -3), 0.9, 4)
		"foot":
			# Three narrow, articulated talons: distinct real open gaps.
			faceted_box(p, Vector3i(-4, -1, -4),
					Vector3i(4, 0, 2), 4, 2)
			for x in [-4, 0, 4]:
				rod(p, Vector3i(x, -1, -3),
						Vector3i(x, -2, -14), 0.9, 4)
				p.fill_box(Vector3i(x, -2, -15),
						Vector3i(x, -2, -15), 8)
			for x in [-2, 2]:
				p.carve_box(Vector3i(x, -2, -14),
						Vector3i(x, -1, -7))
			rod(p, Vector3i(0, 0, 2),
					Vector3i(0, -1, 6), 0.8, 8)


## A one-microcell panel seam on the visible knee guards and armor cutlines,
## applied after actual cell refinement. This must NOT plug any open weapon.
static func fine(p: VoxelPart) -> void:
	var scale := p.detail_scale
	if scale < 2:
		return
	# Large armor hulls gain *real* 25mm-scale chamfers; smooth normals alone
	# cannot fix a 75mm rectangular silhouette. Thin hocks, claws, turret
	# bores and missile opening rings are deliberately left untouched.
	var shape := p.detail_style.trim_prefix("v4_")
	if p.name == "Torso" and shape in ["atlas", "hunchback", "wolverine"]:
		_chamfer_real_microvoxels(p, 2 if shape != "wolverine" else 1)
	if p.name.ends_with("_shin"):
		for y in [-5, -8]:
			p.paint_box(Vector3i(-2 * scale, y * scale, -3 * scale),
					Vector3i(2 * scale, y * scale, -3 * scale), 8)
	if p.name == "Torso":
		for y in [-7, -3]:
			p.paint_box(Vector3i(-3 * scale, y * scale, -4 * scale),
					Vector3i(3 * scale, y * scale, -4 * scale), 8)


## Actual two-axis corner removal AFTER coarse-to-fine refinement. Only
## armor classes can be cut, and only where a multi-cell panel has spare
## support inside; never erase open tubes, exposed actuators, or glass.
static func _chamfer_real_microvoxels(p: VoxelPart, radius: int) -> void:
	var remove: Array[Vector3i] = []
	var directions := [Vector3i.RIGHT, Vector3i.UP, Vector3i.BACK]
	for cell: Vector3i in p.cells:
		var mat: int = int(p.cells[cell])
		if mat != 0 and mat != 4 and mat != 6 and mat != 9:
			continue
		var boundary_axes := 0
		var secure_support := 0
		for axis in directions:
			var edge_plus := not p.cells.has(cell + axis)
			var edge_minus := not p.cells.has(cell - axis)
			if radius == 2:
				edge_plus = edge_plus or not p.cells.has(cell + axis * 2)
				edge_minus = edge_minus or not p.cells.has(cell - axis * 2)
			if edge_plus or edge_minus:
				boundary_axes += 1
			else:
				secure_support += 1
		# Trim a thick panel's outside corner without severing a thin
		# actuator shaft or the root of an armor rib. This checks the
		# two-axis cross-section only; the third axis carries the panel.
		if boundary_axes >= 2 and secure_support >= 1:
			remove.append(cell)
	for cell in remove:
		p.cells.erase(cell)
