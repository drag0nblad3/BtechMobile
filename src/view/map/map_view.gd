class_name MapView
extends Node3D
## Renders a BattleMap: one MultiMesh of hex prisms per terrain type,
## plus woods, water and building props from their own helpers.

const SHADER := preload("res://src/view/shaders/terrain.gdshader")
const INSET := 0.97  ## Slight gap between hexes shows the grid.
## Hex top colors for ice, mud and snow (Surfaces), replacing the terrain's.
const SURFACE_TOPS := {"ice": Color("#b8d4e3"), "mud": Color("#5a4632"), "snow": Color("#e8ecef")}
## Shader pattern index per TerrainType.pattern (see terrain.gdshader).
const PATTERNS := {"grass": 0, "rocks": 1, "paving": 2, "rubble": 3, "riverbed": 4, "forest": 5}

var map: BattleMap
var buildings: BuildingProps
var building_scars := {}  ## Cosmetic wall holes per hex; kept across rebuilds.


func build(battle_map: BattleMap) -> void:
	map = battle_map
	var noise := _noise_texture()
	var mesh := HexMesh.prism(HexLayout.HEX_SIZE * INSET)
	var by_type := {}  # [TerrainType, surface] -> Array[MapTile]
	for t: MapTile in map.tiles.values():
		by_type.get_or_add([t.terrain, t.surface], []).append(t)
	for key: Array in by_type:
		add_child(_prism_layer(mesh, by_type[key], key[0], noise, key[1]))
	add_child(WoodsProps.build(map))
	add_child(GroundScatter.build(map))
	add_child(WaterSurfaces.build(map))
	add_child(BridgeProps.build(map))
	buildings = BuildingProps.build(map, building_scars)
	add_child(buildings)
	add_child(FireProps.build(map))
	add_child(_ground_plane())


## Redraws everything, e.g. after a building collapses into rubble.
func rebuild() -> void:
	for c in get_children():
		c.queue_free()
	build(map)


func _prism_layer(mesh: Mesh, tiles: Array, terrain: TerrainType, noise: Texture2D,
		surface := "") -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = tiles.size()
	var range_ := map.level_range()
	for i in tiles.size():
		var t: MapTile = tiles[i]
		var top := HexLayout.tile_top(t)
		var height := top.y - HexLayout.BASE_Y
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(1, height, 1)), top))
		mm.set_instance_color(i, _level_tint(t.floor_level(), range_))
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("top_color", SURFACE_TOPS.get(surface, terrain.top_color))
	mat.set_shader_parameter("detail_color", terrain.detail_color)
	mat.set_shader_parameter("noise_tex", noise)
	mat.set_shader_parameter("pattern", 0 if surface != "" else PATTERNS.get(terrain.pattern, 0))
	var inst := MultiMeshInstance3D.new()
	inst.name = "Terrain_%s%s" % [terrain.id, "_" + surface if surface != "" else ""]
	inst.multimesh = mm
	inst.material_override = mat
	return inst


## Higher ground is slightly brighter so levels read at a glance.
func _level_tint(level: int, range_: Vector2i) -> Color:
	var span := maxf(1.0, range_.y - range_.x)
	var v := 0.7 + 0.3 * (level - range_.x) / span
	return Color(v, v, v)


## Dark slab under the map; shows through the gaps as grid lines.
func _ground_plane() -> MeshInstance3D:
	var box := HexLayout.map_bounds(map)
	var plane := PlaneMesh.new()
	plane.size = Vector2(box.size.x, box.size.z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.07)
	plane.material = mat
	var inst := MeshInstance3D.new()
	inst.mesh = plane
	inst.position = box.get_center() + Vector3(0, HexLayout.BASE_Y, 0)
	return inst


func _noise_texture() -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.02
	n.fractal_octaves = 4
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.generate_mipmaps = true
	tex.noise = n
	return tex
