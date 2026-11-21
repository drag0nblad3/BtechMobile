class_name VxBuildingStyles
extends RefCounted
## One look per building class, built on VxBuildingGen primitives. Every
## style reaches `levels` x PER_LEVEL voxels (its game height); roof gear
## may stand a little above that.

const HOUSE_WALLS := ["#d8cfb8", "#c9b79a", "#b8c4c8", "#d6c2a8", "#c4a98c"]
const HOUSE_ROOFS := ["#8a3b2e", "#5b4a3e", "#4a5560", "#6d3f2a"]
const SHED_WALLS := ["#9a8466", "#8c8c7c", "#7f6e57", "#8a7a5a"]
const OFFICE_WALLS := ["#8a5a44", "#a39886", "#7d7468", "#94603f"]
const TOWER_WALLS := ["#77777a", "#8a8680", "#5f6268", "#6e706a"]
const BUNKER_WALLS := ["#4b5060", "#51564a", "#4a4e52"]
const ROOF_GREY := Color("#55544f")


## Small house with a stepped gable roof, sometimes a chimney.
static func house(g: VxBuildingGen, levels: int) -> void:
	var top := levels * VxBuildingGen.PER_LEVEL
	var hz := g.rng.randi_range(4, 6)
	var hx := mini(g.rng.randi_range(5, 7), VxBuildingGen.max_half_x(hz + 1) - 1)
	var wall := Color(_pick(g, HOUSE_WALLS))
	var roof := Color(_pick(g, HOUSE_ROOFS))
	var walls := maxi(top - 3, 4)
	var win := func(u: int, y: int) -> bool: return y % 6 in [1, 2] and u % 4 in [1, 2]
	g.shell(Vector3i(-hx, 0, -hz), Vector3i(hx - 1, walls - 2, hz - 1), wall, wall, win, 0.25)
	for k in 4:  # gable steps, ridge along x
		var z0 := -hz - 1 + k
		var z1 := hz - k
		if z1 < z0:
			break
		VxGrid.box(g.cells, Vector3i(-hx - 1, walls + k, z0), Vector3i(hx, walls + k, z1), roof.darkened(0.05 * k))
	g.door(-1, 0, hz - 1, 4)
	if g.rng.randf() < 0.6:
		var cx := g.rng.randi_range(-hx + 1, hx - 3)
		VxGrid.box(g.cells, Vector3i(cx, walls + 1, -2), Vector3i(cx + 1, walls + 5, -1), Color("#6b5a4e"))


## Corrugated warehouse: wide, ribbed walls, a roll-up door, skylights.
static func warehouse(g: VxBuildingGen, levels: int) -> void:
	var top := levels * VxBuildingGen.PER_LEVEL
	var hz := g.rng.randi_range(6, 8)
	var hx := VxBuildingGen.max_half_x(hz)
	var wall := Color(_pick(g, SHED_WALLS))
	g.shell(Vector3i(-hx, 0, -hz), Vector3i(hx - 1, top - 2, hz - 1), wall, ROOF_GREY)
	for x in range(-hx, hx, 2):  # ribs: darker every other column
		for y in range(0, top - 1):
			g.cells[Vector3i(x, y, hz - 1)] = wall.darkened(0.12)
			g.cells[Vector3i(x, y, -hz)] = wall.darkened(0.12)
	g.door(-3, 2, hz - 1, mini(top - 2, 5))
	for x in range(-hx + 2, hx - 2, 4):  # skylight strip
		VxGrid.box(g.cells, Vector3i(x, top - 1, -2), Vector3i(x + 1, top - 1, 1), Color("#8fa4ad"))


## Brick or concrete offices: window grid, parapet and roof AC units.
static func office(g: VxBuildingGen, levels: int) -> void:
	var top := levels * VxBuildingGen.PER_LEVEL
	var hz := g.rng.randi_range(6, 8)
	var hx := VxBuildingGen.max_half_x(hz)
	var wall := Color(_pick(g, OFFICE_WALLS))
	var win := func(u: int, y: int) -> bool: return y % 6 in [2, 3, 4] and u % 3 != 0 and y > 0
	g.shell(Vector3i(-hx, 0, -hz), Vector3i(hx - 1, top - 3, hz - 1), wall, ROOF_GREY, win)
	_parapet(g, -hx, hx - 1, -hz, hz - 1, top - 1, wall.darkened(0.15))
	g.door(-1, 1, hz - 1, 4)
	for i in g.rng.randi_range(1, 3):
		var x := g.rng.randi_range(-hx + 2, hx - 5)
		var z := g.rng.randi_range(-hz + 2, hz - 5)
		VxGrid.box(g.cells, Vector3i(x, top - 1, z), Vector3i(x + 2, top, z + 2), Color("#9a9c98"))


## Concrete tower: ribbon windows, setbacks above level 2, tank or mast.
static func tower(g: VxBuildingGen, levels: int) -> void:
	var top := levels * VxBuildingGen.PER_LEVEL
	var hz := g.rng.randi_range(6, 8)
	var hx := VxBuildingGen.max_half_x(hz)
	var wall := Color(_pick(g, TOWER_WALLS))
	var win := func(u: int, y: int) -> bool: return y % 6 in [2, 3, 4] and u % 5 != 0 and y > 0
	var split := top if levels < 3 else 2 * VxBuildingGen.PER_LEVEL
	g.shell(Vector3i(-hx, 0, -hz), Vector3i(hx - 1, split - 2, hz - 1), wall, ROOF_GREY, win, 0.2)
	if split < top:  # narrower upper floors
		g.shell(Vector3i(-hx + 2, split, -hz + 2), Vector3i(hx - 3, top - 2, hz - 3), wall.lightened(0.05), ROOF_GREY, win, 0.2)
	g.door(-2, 1, hz - 1, 4)
	var inset := 0 if split == top else 2
	if g.rng.randf() < 0.5:  # water tank on legs
		VxGrid.box(g.cells, Vector3i(-hx + inset + 2, top, -2), Vector3i(-hx + inset + 4, top + 4, 0), Color("#6b5240"))
	else:  # antenna mast
		VxGrid.box(g.cells, Vector3i(0, top, 0), Vector3i(0, top + 7, 0), Color("#b0b3b5"))
		g.cells[Vector3i(0, top + 8, 0)] = Color("#d23a2a")


## Hardened bunker: hex footprint, sloped stepped walls, firing slits, hatch.
static func bunker(g: VxBuildingGen, levels: int) -> void:
	var top := levels * VxBuildingGen.PER_LEVEL
	var wall := Color(_pick(g, BUNKER_WALLS))
	var n := int(VxBuildingGen.RADIUS) + 1
	for y in top:
		var r := VxBuildingGen.RADIUS - 0.5 - y * 0.35
		for x in range(-n, n):
			for z in range(-n, n):
				if not VxBuildingGen.in_hex(x, z, r):
					continue
				var edge := not VxBuildingGen.in_hex(x, z, r - 1.2)
				var slit := edge and y % 6 == 3 and (x + z) % 4 == 0
				g.cells[Vector3i(x, y, z)] = VxBuildingGen.GLASS.darkened(0.4) if slit else (wall if y % 4 < 2 else wall.darkened(0.06))
	VxGrid.box(g.cells, Vector3i(-1, top, -1), Vector3i(1, top, 1), wall.darkened(0.25))


static func _parapet(g: VxBuildingGen, x0: int, x1: int, z0: int, z1: int, y: int, c: Color) -> void:
	for x in range(x0, x1 + 1):
		g.cells[Vector3i(x, y, z0)] = c
		g.cells[Vector3i(x, y, z1)] = c
	for z in range(z0, z1 + 1):
		g.cells[Vector3i(x0, y, z)] = c
		g.cells[Vector3i(x1, y, z)] = c


static func _pick(g: VxBuildingGen, arr: Array) -> String:
	return arr[g.rng.randi() % arr.size()]
