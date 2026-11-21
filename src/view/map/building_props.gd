class_name BuildingProps
extends Node3D
## Voxel buildings from VxBuildingGen, one per building hex. Meshes are
## cached per (class, height, variant) and turned in 60-degree steps, so a
## city of many buildings costs only a handful of builds. A building with
## a 'Mech's model in its hex turns see-through so the 'Mech stays visible.
## Hits knock cosmetic holes out of the walls (scars); MapView keeps the
## scar list so they survive a redraw.

const VARIANTS := 3
const GHOST_ALPHA := 0.3
const POLL := 0.2  ## Seconds between checks for 'Mechs inside.
const MAX_SCARS := 12  ## Per building; later hits only flash.

static var _cache := {}  # [type_id, levels, variant] -> ArrayMesh
static var _ghost: StandardMaterial3D

var scars := {}  # Vector2i -> Array of [Vector3 voxel centre, float radius]
var _by_coord := {}  # Vector2i -> MeshInstance3D
var _tiles := {}  # Vector2i -> MapTile
var _ghosted := {}
var _wait := 0.0


static func build(map: BattleMap, scar_list := {}) -> BuildingProps:
	var root := BuildingProps.new()
	root.name = "Buildings"
	root.scars = scar_list
	for t: MapTile in map.tiles.values():
		if t.building == null:
			continue
		var h := hash(t.coord)
		var inst := MeshInstance3D.new()
		inst.mesh = mesh_for(t.building.type.id, t.building.height, absi(h) % VARIANTS)
		inst.material_override = VxGrid.material()
		inst.position = HexLayout.tile_top(t)
		inst.rotation.y = (absi(h >> 4) % 6) * PI / 3.0
		root.add_child(inst)
		root._by_coord[t.coord] = inst
		root._tiles[t.coord] = t
		if root.scars.has(t.coord):
			inst.mesh = root._scarred(t).mesh()
	return root


static func mesh_for(type_id: String, levels: int, variant: int) -> ArrayMesh:
	var key := [type_id, levels, variant]
	if not _cache.has(key):
		_cache[key] = VxBuildingGen.generate(type_id, levels, variant).mesh()
	return _cache[key]


## Knocks a hole in the wall of the building at `coord` that faces the
## world point `from`; bigger for more damage. Returns the hole's world
## position (or the hex centre once the building has all its scars).
func scar(coord: Vector2i, from: Vector3, damage: int) -> Vector3:
	var inst: MeshInstance3D = _by_coord.get(coord)
	if inst == null:
		return Vector3.ZERO
	var t: MapTile = _tiles[coord]
	var list: Array = scars.get_or_add(coord, [])
	var top := t.building.height * VxBuildingGen.PER_LEVEL
	if list.size() >= MAX_SCARS:
		return inst.position + Vector3(0, top * VxBuildingGen.PITCH * 0.5, 0)
	var g := _scarred(t)
	var local := inst.transform.affine_inverse() * from / VxBuildingGen.PITCH
	var y := 1 + absi(hash([coord, list.size()])) % maxi(1, top - 2)
	var hit := g.hit_cell(Vector2(local.x, local.z), y)
	var r := clampf(1.2 + damage * 0.12, 1.5, 3.5)
	list.append([hit, r])
	g.carve(hit, r)
	inst.mesh = g.mesh()
	return inst.transform * (hit * VxBuildingGen.PITCH)


## The building's generator with every scar so far carved out.
func _scarred(t: MapTile) -> VxBuildingGen:
	var g := VxBuildingGen.generate(t.building.type.id, t.building.height, absi(hash(t.coord)) % VARIANTS)
	for s: Array in scars.get(t.coord, []):
		g.carve(s[0], s[1])
	return g


## Makes the buildings on these hexes see-through and restores the rest.
func set_occupied(coords: Dictionary) -> void:
	for c: Vector2i in _by_coord:
		var inside := coords.has(c)
		if inside != _ghosted.has(c):
			_by_coord[c].material_override = ghost_material() if inside else VxGrid.material()
			if inside:
				_ghosted[c] = true
			else:
				_ghosted.erase(c)


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0 or _by_coord.is_empty():
		return
	_wait = POLL
	var inside := {}
	for v: Node in get_tree().get_nodes_in_group(UnitView.GROUP):
		if v is Node3D and v.visible:
			inside[HexLayout.from_world((v as Node3D).global_position)] = true
	set_occupied(inside)


static func ghost_material() -> StandardMaterial3D:
	if _ghost == null:
		_ghost = VxGrid.material().duplicate()
		_ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ghost.albedo_color = Color(1, 1, 1, GHOST_ALPHA)
	return _ghost
