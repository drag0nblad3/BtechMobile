class_name VxBridgeGen
extends VxBuildingGen
## Procedural voxel bridge hex: a stone pier from the ground or river bed,
## a paved deck slab, and a parapet along each open edge. Built on
## VxBuildingGen so shots carve the same cosmetic holes as in buildings.
## Cell y = 0 is the bed; the deck top is at `deck_top` (one voxel above
## the deck's level, so it stands clear of a water surface).

const DECK := 3                   ## Slab thickness in voxels.
const STONE := Color("#77736b")
const PAVING := Color("#5f5e5a")
const PIER := Color("#625d55")

var deck_top := 0


## rise: voxels from the bed to the deck top. open: 6 bools, one per hex
## edge (facing 0 = north, clockwise), true where a parapet belongs.
static func make(rise: int, open: Array, variant: int) -> VxBridgeGen:
	var g := VxBridgeGen.new()
	g.rng.seed = hash(["bridge", rise, open, variant])
	g.deck_top = maxi(1, rise)
	g._pier()
	g._deck()
	for f in 6:
		if open[f]:
			g._parapet(f)
	return g


func _pier() -> void:
	var bottom := deck_top - DECK
	if bottom <= 0:
		return
	for x in range(-3, 3):
		for z in range(-3, 3):
			if Vector2(x + 0.5, z + 0.5).length() <= 2.9:
				VxGrid.box(cells, Vector3i(x, 0, z), Vector3i(x, bottom - 1, z),
						PIER.darkened(0.1) if posmod(x + z, 2) == 0 else PIER)
	# A cutwater footing where the pier meets the bed.
	for x in range(-4, 4):
		for z in range(-4, 4):
			if Vector2(x + 0.5, z + 0.5).length() <= 3.9:
				cells[Vector3i(x, 0, z)] = PIER.darkened(0.2)


func _deck() -> void:
	var n := int(RADIUS) + 1
	for x in range(-n, n):
		for z in range(-n, n):
			if not in_hex(x, z, RADIUS + 0.4):
				continue
			for y in range(maxi(0, deck_top - DECK), deck_top - 1):
				cells[Vector3i(x, y, z)] = STONE
			var stone := PAVING.lightened(0.08) if posmod(floori(x / 2.0) + floori(z / 2.0), 2) == 0 else PAVING
			cells[Vector3i(x, deck_top - 1, z)] = stone.darkened(0.15) if rng.randf() < 0.05 else stone


## Two-voxel wall on the rim cells nearest edge f.
func _parapet(f: int) -> void:
	var w := HexLayout.to_world(Hex.neighbor(Vector2i.ZERO, f))
	var dir := Vector2(w.x, w.z).normalized()
	var inner := RADIUS * 0.866 - 1.4
	var n := int(RADIUS) + 1
	for x in range(-n, n):
		for z in range(-n, n):
			if not in_hex(x, z, RADIUS + 0.4):
				continue
			if Vector2(x + 0.5, z + 0.5).dot(dir) >= inner:
				for y in range(deck_top, deck_top + 2):
					cells[Vector3i(x, y, z)] = STONE.lightened(0.05)
