class_name VxTrees
extends RefCounted
## Voxel tree meshes: tiered conifers and round broadleaf trees, a few
## seeded variants each. Every tier or canopy shell is one colour so the
## greedy mesher keeps them at a few hundred triangles.

const PITCH := 0.075  ## Coarse enough that a dense forest stays cheap on phones.
const CONIFERS := 3
const BROADLEAF := 3
const TRUNK := Color("#4e3826")
const NEEDLES := [Color("#2a5a2e"), Color("#326a34"), Color("#3c7a3a"), Color("#4a8a42")]
const LEAVES := [Color("#3f7a2e"), Color("#4f8a34"), Color("#5f9a3a"), Color("#6f8a2e")]

static var _cache := {}  # [kind, variant] -> ArrayMesh


## kind "conifer" or "broadleaf"; variant 0 .. count - 1.
static func mesh(kind: String, variant: int) -> ArrayMesh:
	var key := [kind, variant]
	if not _cache.has(key):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(key)
		var cells := conifer(rng) if kind == "conifer" else broadleaf(rng)
		_cache[key] = VxGrid.mesh(cells, PITCH, Vector3(0.5, 0.0, 0.5))
	return _cache[key]


static func conifer(rng: RandomNumberGenerator) -> Dictionary:
	var cells := {}
	var trunk_h := rng.randi_range(1, 2)
	VxGrid.box(cells, Vector3i(0, 0, 0), Vector3i(0, trunk_h + 2, 0), TRUNK)
	var tiers := rng.randi_range(3, 4)
	var r := rng.randf_range(2.9, 3.5)
	var y := trunk_h
	for i in tiers:
		var h := 3
		var tint: Color = NEEDLES[mini(i, NEEDLES.size() - 1)]
		for dy in h:  # each tier narrows toward its top
			_disk(cells, y + dy, r - dy * 0.8, tint)
		y += h - 1
		r -= rng.randf_range(0.6, 0.8)
	cells[Vector3i(0, y + 1, 0)] = NEEDLES[NEEDLES.size() - 1]
	return cells


static func broadleaf(rng: RandomNumberGenerator) -> Dictionary:
	var cells := {}
	var trunk_h := rng.randi_range(3, 5)
	VxGrid.box(cells, Vector3i(0, 0, 0), Vector3i(0, trunk_h + 1, 0), TRUNK)
	var leaf: Color = LEAVES[rng.randi() % LEAVES.size()]
	var rx := rng.randf_range(2.9, 3.6)
	var ry := rng.randf_range(2.4, 3.0)
	var cy := trunk_h + ry - 0.5
	_blob(cells, Vector3(0, cy, 0), Vector3(rx, ry, rx), leaf, leaf.darkened(0.18))
	if rng.randf() < 0.7:  # a second lump makes the crown uneven
		var off := Vector3(rng.randf_range(-2, 2), ry * 0.6, rng.randf_range(-2, 2))
		_blob(cells, Vector3(0, cy, 0) + off, Vector3(rx, ry, rx) * 0.6, leaf.lightened(0.08), leaf.darkened(0.18))
	return cells


## Filled disk of radius r (voxels) at height y, centered on the trunk.
static func _disk(cells: Dictionary, y: int, r: float, c: Color) -> void:
	var n := ceili(r)
	for x in range(-n, n + 1):
		for z in range(-n, n + 1):
			if x * x + z * z <= r * r:
				cells[Vector3i(x, y, z)] = c


## Ellipsoid; its lower half is darker so the crown reads as lit from above.
static func _blob(cells: Dictionary, center: Vector3, radii: Vector3, top: Color, under: Color) -> void:
	for x in range(floori(center.x - radii.x), ceili(center.x + radii.x) + 1):
		for y in range(floori(center.y - radii.y), ceili(center.y + radii.y) + 1):
			for z in range(floori(center.z - radii.z), ceili(center.z + radii.z) + 1):
				var d := Vector3(x, y, z) - center
				if (d / radii).length_squared() <= 1.0:
					cells[Vector3i(x, y, z)] = top if d.y > -radii.y * 0.25 else under
