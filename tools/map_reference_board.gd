class_name MapReferenceBoard
extends RefCounted
## Offline analysis of externally supplied MegaMek .board files. No official
## board layouts are distributed with this project. Unsupported terrain is
## rejected instead of silently substituting clear hexes.

const ALLOWED := ["woods", "foliage_elev", "water", "rough", "rubble", "road",
	"pavement", "building", "bldg_elev", "bldg_cf", "bldg_fluff", "fluff"]
const CLASSES := ["light", "medium", "heavy", "hardened"]


static func parse(source: String, name: String) -> Dictionary:
	var w := 0
	var h := 0
	var cells := {}
	var buildings: Array = []
	for line in source.split("\n"):
		var text := line.strip_edges()
		if text.begins_with("size "):
			var size := text.split(" ", false)
			if size.size() != 3:
				return {}
			w = int(size[1])
			h = int(size[2])
		elif text.begins_with("hex "):
			var quoted := text.split('"')
			if quoted.size() < 3:
				return {}
			var header := quoted[0].split(" ", false)
			if header.size() != 3:
				return {}
			var label := header[1]
			var features := {}
			for item in quoted[1].split(";", false):
				var parts := item.split(":")
				if parts.size() < 2 or not ALLOWED.has(parts[0]):
					return {}
				features[parts[0]] = int(parts[1])
			if int(features.get("woods", 0)) > 2 or int(features.get("foliage_elev", 2)) != 2:
				return {}
			var token := "c"
			if features.has("water"):
				token = "w"
			elif features.has("woods"):
				token = "H" if int(features["woods"]) == 2 else "L"
			elif features.has("rubble"):
				token = "u"
			elif features.has("rough"):
				token = "r"
			elif features.has("road") or features.has("pavement"):
				token = "p"
			var value := token + header[2]
			if token == "w":
				value += "d%d" % int(features["water"])
			if features.has("building"):
				var kind := int(features["building"]) - 1
				if kind < 0 or kind >= CLASSES.size():
					return {}
				buildings.append({"hex": label, "type": CLASSES[kind],
					"height": maxi(1, int(features.get("bldg_elev", 1)))})
			cells[label] = value
	if w <= 0 or h <= 0 or cells.size() != w * h:
		return {}
	var rows: Array = []
	for y in h:
		var row := PackedStringArray()
		for x in w:
			var key := "%02d%02d" % [x + 1, y + 1]
			if not cells.has(key):
				return {}
			row.append(cells[key])
		rows.append(" ".join(row))
	return {"name": name, "rows": rows, "buildings": buildings}
