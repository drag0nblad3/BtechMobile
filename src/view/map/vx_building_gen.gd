class_name VxBuildingGen
extends RefCounted
## Procedural voxel building for one hex: a sidewalk slab plus one style
## per building class (VxBuildingStyles), seeded so a variant always looks
## the same. Walls are hollow shells; `hidden` boxes stand for the inside
## so the mesher never draws faces nobody can see.

const PITCH := 0.075     ## World units per voxel: 6 voxels per level.
const PER_LEVEL := 6
const RADIUS := 10.5     ## Usable hex corner radius in voxels.
const GLASS := Color("#26313c")
const LIT := Color("#e9c873")
const SLAB := Color("#7b7a74")
const SCORCH := Color("#1c1916")

var cells := {}          ## Vector3i -> Color
var hidden: Array = []   ## [Vector3i, Vector3i] solid boxes that aren't drawn
var carved := {}         ## Cells shot away (cosmetic scars), never refilled
var rng := RandomNumberGenerator.new()


static func generate(type_id: String, levels: int, variant: int) -> VxBuildingGen:
	var g := VxBuildingGen.new()
	g.rng.seed = hash([type_id, levels, variant])
	g.slab()
	match type_id:
		"civilian": VxBuildingStyles.house(g, levels)
		"light":
			if variant % 2 == 0:
				VxBuildingStyles.warehouse(g, levels)
			else:
				VxFacilityStyles.hangar(g, levels)
		"medium":
			if variant % 2 == 0:
				VxBuildingStyles.office(g, levels)
			else:
				VxFacilityStyles.utility(g, levels)
		"heavy": VxBuildingStyles.tower(g, levels)
		_: VxBuildingStyles.bunker(g, levels)
	return g


func mesh() -> ArrayMesh:
	return VxGrid.mesh(_with_hidden(), PITCH, Vector3.ZERO)


## Knocks a round hole of radius r (voxels) out of the walls and scorches
## its rim. Cosmetic only: building damage comes from the rules.
func carve(center: Vector3, r: float) -> void:
	var n := ceili(r + 1.5)
	var base := Vector3i(center.floor())
	for x in range(-n, n + 1):
		for y in range(-n, n + 1):
			for z in range(-n, n + 1):
				var c := base + Vector3i(x, y, z)
				if c.y <= 0:
					continue  # keep the footing
				var d := (Vector3(c) + Vector3(0.5, 0.5, 0.5)).distance_to(center)
				if d <= r:
					cells.erase(c)
					carved[c] = true
				elif d <= r + 1.5 and cells.has(c):
					cells[c] = (cells[c] as Color).lerp(SCORCH, 0.6)


## First wall cell met walking in from outside along `dir` at height y.
func hit_cell(dir: Vector2, y: int) -> Vector3:
	var d := dir.normalized()
	for i in range(int(RADIUS * 2.0) + 4, -1, -1):
		var p := Vector3(d.x * i * 0.5, y, d.y * i * 0.5)
		if cells.has(Vector3i(p.floor())):
			return p
	return Vector3(0, y, 0)


## Is the cell's center inside a flat-topped hex of radius r (voxels)?
static func in_hex(x: int, z: int, r: float) -> bool:
	var fx := absf(x + 0.5)
	var fz := absf(z + 0.5)
	return fz <= r * 0.866 and 1.732 * fx + fz <= 1.732 * r


## Widest half-width (x) that fits the hex at half-depth hz.
static func max_half_x(hz: int) -> int:
	return int(RADIUS - hz * 0.577)


## Paved footing one voxel thick that fills the hex; walls overwrite it.
func slab() -> void:
	var n := int(RADIUS) + 1
	for x in range(-n, n):
		for z in range(-n, n):
			if in_hex(x, z, RADIUS + 0.4):
				cells[Vector3i(x, 0, z)] = SLAB.darkened(0.12) if rng.randf() < 0.04 else SLAB


## Hollow block from (x0, y0, z0) to (x1, y1, z1) inclusive with a roof.
## window: Callable(u: int, y: int) -> bool on each wall cell; u runs along the wall.
func shell(a: Vector3i, b: Vector3i, wall: Color, roof: Color, window := Callable(), lit := 0.15) -> void:
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			_wall(Vector3i(x, y, a.z), x - a.x, wall, window, lit)
			_wall(Vector3i(x, y, b.z), x - a.x, wall, window, lit)
		for z in range(a.z + 1, b.z):
			_wall(Vector3i(a.x, y, z), z - a.z, wall, window, lit)
			_wall(Vector3i(b.x, y, z), z - a.z, wall, window, lit)
	VxGrid.box(cells, Vector3i(a.x, b.y + 1, a.z), Vector3i(b.x, b.y + 1, b.z), roof)
	if b.x - a.x > 1 and b.z - a.z > 1:
		hidden.append([Vector3i(a.x + 1, a.y, a.z + 1), Vector3i(b.x - 1, b.y, b.z - 1)])


## Dark doorway cut into the south wall (z = z1) at ground level.
func door(x0: int, x1: int, z: int, height: int) -> void:
	VxGrid.box(cells, Vector3i(x0, 0, z), Vector3i(x1, height - 1, z), GLASS.darkened(0.3))


func _wall(c: Vector3i, u: int, wall: Color, window: Callable, lit: float) -> void:
	if window.is_valid() and window.call(u, c.y):
		cells[c] = LIT if rng.randf() < lit else GLASS
	else:
		cells[c] = wall


func _with_hidden() -> Dictionary:
	if hidden.is_empty() and carved.is_empty():
		return cells
	var solid := cells.duplicate()
	for b: Array in hidden:
		VxGrid.box(solid, b[0], b[1], SCORCH)  # shows as a dark inside through holes
	for c: Vector3i in carved:
		solid.erase(c)
	return solid

