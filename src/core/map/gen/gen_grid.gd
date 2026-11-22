class_name GenGrid
extends RefCounted
## Scratch grid the map generator paints on, indexed by row * w + col
## (mapsheet offset coordinates). `to_dict()` writes the usual map JSON,
## so a generated map loads through MapLoader like a hand-made one.

var w: int
var h: int
var level := PackedInt32Array()
var depth := PackedInt32Array()
var token := PackedStringArray()  ## Terrain token per hex ("c", "L", "w", ...).
var buildings := {}  ## index -> {"type": String, "height": int}
var bridged := {}  ## Water hexes a road crosses: index -> true (GenBridges).
var bridges: Array = []  ## [{"hexes": [index, ...], "type": String, "level": int}]
var _nbrs: Array[PackedInt32Array] = []


func _init(cols: int, rows: int) -> void:
	w = cols
	h = rows
	level.resize(w * h)
	depth.resize(w * h)
	token.resize(w * h)
	token.fill("c")
	for i in w * h:
		var c := Hex.from_offset(Vector2i(col_of(i), row_of(i)))
		var n := PackedInt32Array()
		for f in 6:
			var o := Hex.to_offset(Hex.neighbor(c, f))
			if o.x >= 0 and o.x < w and o.y >= 0 and o.y < h:
				n.append(o.y * w + o.x)
		_nbrs.append(n)


func size() -> int:
	return w * h


func idx(col: int, row: int) -> int:
	return row * w + col


func col_of(i: int) -> int:
	return i % w


@warning_ignore("integer_division")
func row_of(i: int) -> int:
	return i / w


func neighbors(i: int) -> PackedInt32Array:
	return _nbrs[i]


func is_water(i: int) -> bool:
	return token[i] == "w" and depth[i] > 0


## Dry, unbuilt hex that cover (woods, rough) may grow on.
func is_open_ground(i: int) -> bool:
	return token[i] == "c" and not buildings.has(i)


## Hex centre in flat space, for sampling noise without stretching.
func world(i: int) -> Vector2:
	var col := col_of(i)
	return Vector2(col * 1.5, (row_of(i) + 0.5 * (col % 2)) * HexLayout.SQRT3)


## Within `n` rows of the top or bottom edge (home edges, deployment).
func near_home_edge(i: int, n: int = 2) -> bool:
	return row_of(i) < n or row_of(i) >= h - n


func make_water(i: int, surface: int, d: int) -> void:
	token[i] = "w"
	level[i] = surface
	depth[i] = d
	buildings.erase(i)


func to_dict(map_name: String) -> Dictionary:
	var rows: Array = []
	for r in h:
		var toks := PackedStringArray()
		for c in w:
			var i := idx(c, r)
			var t := "%s%d" % [token[i], level[i]]
			if depth[i] > 0:
				t += "d%d" % depth[i]
			toks.append(t)
		rows.append(" ".join(toks))
	var blds: Array = []
	var keys := buildings.keys()
	keys.sort()
	for i: int in keys:
		var b: Dictionary = buildings[i]
		blds.append({"hex": Hex.label(Hex.from_offset(Vector2i(col_of(i), row_of(i)))),
				"type": b["type"], "height": b["height"]})
	var spans: Array = []
	for b: Dictionary in bridges:
		var labels: Array = []
		for i: int in b["hexes"]:
			labels.append(Hex.label(Hex.from_offset(Vector2i(col_of(i), row_of(i)))))
		spans.append({"hexes": labels, "type": b["type"], "level": b["level"]})
	return {"name": map_name, "rows": rows, "buildings": blds, "bridges": spans}
