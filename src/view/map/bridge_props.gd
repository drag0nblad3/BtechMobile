class_name BridgeProps
extends Node3D
## Voxel bridges from VxBridgeGen, one per bridge hex, standing on the
## ground or river bed. Hits knock cosmetic holes out of the stonework
## (scars, kept by MapView so they survive a redraw); only the rules decide
## when a bridge comes down.

const VARIANTS := 3
const MAX_SCARS := 10
const STONE := VxBridgeGen.STONE
const MAX_CACHED := 48
static var _cache: Dictionary = {}

var scars := {}  # Vector2i -> Array of [Vector3 voxel centre, float radius]
var _by_coord := {}  # Vector2i -> MeshInstance3D
var _map: BattleMap


static func build(map: BattleMap, scar_list := {}) -> BridgeProps:
	var root := BridgeProps.new()
	root.name = "Bridges"
	root.scars = scar_list
	root._map = map
	for t: MapTile in map.tiles.values():
		if t.bridge == null:
			continue
		var inst := MeshInstance3D.new()
		inst.material_override = VxGrid.material()
		inst.position = HexLayout.to_world(t.coord, t.floor_level())
		root.add_child(inst)
		root._by_coord[t.coord] = inst
		inst.mesh = root._mesh_for(t)
	return root


func _shape(t: MapTile) -> Array:
	var open: Array = []
	for f in 6:
		open.append(_open_edge(t, Hex.neighbor(t.coord, f)))
	var rise := (t.bridge.level - t.floor_level()) * VxBuildingGen.PER_LEVEL + 1
	return [rise, open, absi(hash(t.coord)) % VARIANTS]


func _mesh_for(t: MapTile) -> ArrayMesh:
	if not scars.get(t.coord, []).is_empty():
		return _scarred(t).mesh()
	var key := _shape(t)
	if not _cache.has(key):
		if _cache.size() >= MAX_CACHED:
			_cache.erase(_cache.keys()[0])
		_cache[key] = VxBridgeGen.make(key[0], key[1], key[2]).mesh()
	return _cache[key]


## The bridge hex's generator, with every scar so far carved out.
func _scarred(t: MapTile) -> VxBridgeGen:
	var key := _shape(t)
	var g := VxBridgeGen.make(key[0], key[1], key[2])
	for s: Array in scars.get(t.coord, []):
		g.carve(s[0], s[1])
	return g


## Knocks a hole in the bridge at `coord` on the side facing the world point
## `from`; bigger for more damage. Returns the hole's world position.
func scar(coord: Vector2i, from: Vector3, damage: int) -> Vector3:
	var inst: MeshInstance3D = _by_coord.get(coord)
	var t := _map.get_tile(coord)
	if inst == null or t == null or t.bridge == null:
		return Vector3.ZERO
	var list: Array = scars.get_or_add(coord, [])
	var g := _scarred(t)
	if list.size() >= MAX_SCARS:
		return inst.position + Vector3(0, g.deck_top * VxBuildingGen.PITCH, 0)
	var local := (from - inst.position) / VxBuildingGen.PITCH
	var y := maxi(1, g.deck_top - 1 - absi(hash([coord, list.size()])) % 3)
	var hit := g.hit_cell(Vector2(local.x, local.z), y)
	var r := clampf(1.2 + damage * 0.12, 1.5, 3.5)
	list.append([hit, r])
	g.carve(hit, r)
	inst.mesh = g.mesh()
	return inst.position + hit * VxBuildingGen.PITCH


## A parapet goes on edges facing water or a drop, not onto land at deck level.
func _open_edge(t: MapTile, c: Vector2i) -> bool:
	var n := _map.get_tile(c)
	if n == null or n.bridge != null:
		return false
	return n.is_water() or n.floor_level() < t.bridge.level - 1
