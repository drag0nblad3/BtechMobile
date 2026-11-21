class_name BuildingProps
extends Node3D
## Voxel buildings from VxBuildingGen, one per building hex. Meshes are
## cached per (class, height, variant) and turned in 60-degree steps, so a
## city of many buildings costs only a handful of builds. A building with
## a 'Mech's model in its hex turns see-through so the 'Mech stays visible.

const VARIANTS := 3
const GHOST_ALPHA := 0.3
const POLL := 0.2  ## Seconds between checks for 'Mechs inside.

static var _cache := {}  # [type_id, levels, variant] -> ArrayMesh
static var _ghost: StandardMaterial3D

var _by_coord := {}  # Vector2i -> MeshInstance3D
var _ghosted := {}
var _wait := 0.0


static func build(map: BattleMap) -> BuildingProps:
	var root := BuildingProps.new()
	root.name = "Buildings"
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
	return root


static func mesh_for(type_id: String, levels: int, variant: int) -> ArrayMesh:
	var key := [type_id, levels, variant]
	if not _cache.has(key):
		_cache[key] = VxBuildingGen.generate(type_id, levels, variant).mesh()
	return _cache[key]


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
