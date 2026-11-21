class_name BridgeProps
extends RefCounted
## Bridge decks: a stone slab at each bridge hex's deck level, a low parapet
## along every edge that faces water or open air (not the road or the next
## deck), and a pier down to the ground or river bed beneath.

const DECK := 0.16    ## Slab thickness, world units.
const LIFT := 0.06    ## Deck top sits just above its level, clear of the water cap.
const WALL := 0.16    ## Parapet height.
const STONE := Color("6b6862")


static func build(map: BattleMap) -> Node3D:
	var root := Node3D.new()
	root.name = "Bridges"
	var slab := HexMesh.prism(HexLayout.HEX_SIZE * 0.99)
	var pier := CylinderMesh.new()
	pier.top_radius = 0.2
	pier.bottom_radius = 0.26
	pier.height = 1.0
	var wall := BoxMesh.new()
	wall.size = Vector3(HexLayout.HEX_SIZE, WALL, 0.1)
	for t: MapTile in map.tiles.values():
		if t.bridge == null:
			continue
		var tint := STONE.lerp(t.bridge.type.color, 0.25)
		var top := HexLayout.to_world(t.coord, t.bridge.level) + Vector3(0, LIFT, 0)
		root.add_child(_part(slab, Transform3D(Basis.from_scale(Vector3(1, DECK, 1)), top), tint))
		for f in 6:
			if _open_edge(map, t, Hex.neighbor(t.coord, f)):
				root.add_child(_part(wall, _edge_xf(top, f), tint.darkened(0.2)))
		var bed := HexLayout.level_y(t.floor_level())
		var drop := top.y - DECK - bed
		if drop > 0.05:
			var mid := Vector3(top.x, bed + drop * 0.5, top.z)
			root.add_child(_part(pier, Transform3D(Basis.from_scale(Vector3(1, drop, 1)), mid), tint.darkened(0.35)))
	return root


## A parapet goes on edges facing water or a drop, not onto land at deck level.
static func _open_edge(map: BattleMap, t: MapTile, c: Vector2i) -> bool:
	var n := map.get_tile(c)
	if n == null or n.bridge != null:
		return false
	return n.is_water() or n.floor_level() < t.bridge.level - 1


## The parapet along the hexside towards facing `f` (0 = north, clockwise).
static func _edge_xf(top: Vector3, f: int) -> Transform3D:
	var dir := HexLayout.to_world(Hex.neighbor(Vector2i.ZERO, f)).normalized()
	var at := top + dir * HexLayout.HEX_SIZE * HexLayout.SQRT3 * 0.5 * 0.92 + Vector3(0, WALL * 0.5, 0)
	var basis := Basis(Vector3.UP, atan2(-dir.z, dir.x) + PI / 2.0)
	return Transform3D(basis, at)


static func _part(mesh: Mesh, xf: Transform3D, colour: Color) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.transform = xf
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.95
	inst.material_override = mat
	return inst
