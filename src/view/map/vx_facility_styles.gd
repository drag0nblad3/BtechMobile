class_name VxFacilityStyles
extends RefCounted
## Visual alternatives within existing light and medium building classes.
## Preserve footprint, game height and the shared destructible wall system.

static func hangar(g: VxBuildingGen, levels: int) -> void:
	var top := levels * VxBuildingGen.PER_LEVEL
	var hz := 6
	var hx := VxBuildingGen.max_half_x(hz)
	var wall := Color("#68747b")
	g.shell(Vector3i(-hx, 0, -hz), Vector3i(hx - 1, top - 2, hz - 1), wall, Color("#474c51"))
	g.door(-3, 3, hz - 1, mini(4, top - 1))
	for x in [-4, 3]:
		VxGrid.box(g.cells, Vector3i(x, 1, hz - 1), Vector3i(x, top - 2, hz - 1), Color("#c29a4e"))
	for x in range(-hx + 1, hx - 1, 3):
		VxGrid.box(g.cells, Vector3i(x, top - 1, -hz + 1), Vector3i(x, top - 1, hz - 2), Color("#89949b"))


static func utility(g: VxBuildingGen, levels: int) -> void:
	var top := levels * VxBuildingGen.PER_LEVEL
	var hz := 6
	var hx := VxBuildingGen.max_half_x(hz)
	var wall := Color("#978c77")
	g.shell(Vector3i(-hx, 0, -hz), Vector3i(hx - 1, top - 2, hz - 1), wall, Color("#655f58"))
	g.door(-2, 1, hz - 1, mini(4, top - 1))
	for x in range(-hx + 1, hx - 1, 3):
		VxGrid.box(g.cells, Vector3i(x, 2, hz - 1), Vector3i(x + 1, mini(3, top - 2), hz - 1), VxBuildingGen.GLASS)
	for x in [-3, 1]:
		VxGrid.box(g.cells, Vector3i(x, top - 1, -2), Vector3i(x + 2, top - 1, 2), Color("#afb3ac"))
		VxGrid.box(g.cells, Vector3i(x + 1, top - 1, -1), Vector3i(x + 1, top - 1, 1), Color("#454a49"))
