class_name VxLivery
extends RefCounted
## Data-driven cosmetic faction palettes. Materials are shared between units:
## the insignia and stripes are drawn in the armor shader, not extra geometry.

const DATA_PATH := "res://data/graphics/faction_liveries.json"
const PAINT_SHADER := preload("res://src/view/vox/vx_livery.gdshader")
static var _data: Dictionary = {}
static var _materials: Dictionary = {}
static var _loaded := false


static func scheme(faction: String) -> Dictionary:
	if not _loaded:
		_data = JsonFile.read(DATA_PATH)
		_loaded = true
	var id: String = String(_data.get("aliases", {}).get(faction, faction))
	var known: Dictionary = _data.get("factions", {})
	if known.has(id):
		return known[id]
	var key := "clan_fallbacks" if faction.begins_with("clan_") else "other_fallbacks"
	var options: Array = _data.get(key, [])
	if options.is_empty():
		return {"primary": "#5c665e", "secondary": "#b6ac92",
				"insignia": "#ece6cf", "pattern": 1, "badge": 4}
	return options[posmod(faction.hash(), options.size())]


static func material_for(faction: String, side: int) -> ShaderMaterial:
	var key := faction + ":" + str(side)
	if _materials.has(key):
		return _materials[key]
	var colors := scheme(faction)
	var mat := ShaderMaterial.new()
	mat.shader = PAINT_SHADER
	mat.set_shader_parameter("paint_primary", Color(String(colors["primary"])))
	mat.set_shader_parameter("paint_secondary", Color(String(colors["secondary"])))
	mat.set_shader_parameter("badge_ink", Color(String(colors["insignia"])))
	mat.set_shader_parameter("team_mark", PlaceholderMech.SIDE_COLORS[
		posmod(side, PlaceholderMech.SIDE_COLORS.size())])
	mat.set_shader_parameter("paint_pattern", int(colors["pattern"]))
	mat.set_shader_parameter("badge_shape", int(colors["badge"]))
	_materials[key] = mat
	return mat
