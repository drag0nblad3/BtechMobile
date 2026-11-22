extends TestCase
## Final thirty-three shape-first chassis: check low-LOD geometry and the
## correspondence of low/high silhouette recipes without loading every 3x
## detailed mesh into the same CI process.
const IDS := [
	"battleaxe",
	"chameleon",
	"crockett",
	"gunslinger",
	"havoc",
	"hel",
	"helios",
	"howler",
	"hunchback_iic",
	"icarus_ii",
	"katana",
	"lancelot",
	"legionnaire",
	"malice",
	"merlin",
	"nightsky",
	"ostscout",
	"ostwar",
	"penetrator",
	"pillager",
	"sagittaire",
	"scarabus",
	"sentinel",
	"shockwave",
	"shogun",
	"spartan",
	"spector",
	"starslayer",
	"suburbanmech",
	"thunder_hawk",
	"thunder_stallion",
	"venom",
	"ymir"
]

func test_lod_silhouette_and_record_id() -> void:
	var db := UnitDb.load_dir()
	for id: String in IDS:
		var lo: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		var hi: Dictionary = JsonFile.read("res://data/voxels/%s.json" % id)
		check(db.get_def(lo["unit"]) != null, "%s official unit exists" % id)
		check_eq(lo["unit"], hi["unit"])
		check_eq(int(lo["subdivide"]), 1)
		check_eq(int(hi["subdivide"]), 3)
		check_eq(lo["parts"].size(), hi["parts"].size())
		for i in lo["parts"].size():
			var a: Dictionary = lo["parts"][i]
			var b: Dictionary = hi["parts"][i]
			check_eq(a["name"], b["name"])
			if a.has("mirror"):
				continue
			check_eq(a["pivot"], b["pivot"])
			for j in a.get("shapes", []).size():
				if a["shapes"][j].has("loft"):
					check_eq(a["shapes"][j]["loft"], b["shapes"][j]["loft"],
						"%s %s contour drift" % [id,a["name"]])

func test_exclusive_coarse_voxels_and_locations() -> void:
	for id: String in IDS:
		for suffix in ["_shape", ""]:
			var d: Dictionary = JsonFile.read("res://data/voxels/%s%s.json" % [id, suffix])
			d["subdivide"] = 1
			for p: Dictionary in d["parts"]:
				p.erase("detail")
			var m := VxModel.from_dict(d)
			check(m.errors.is_empty(), "%s%s load errors" % [id,suffix])
			var owner := {}
			for p: Dictionary in m.parts:
				for c: Vector3i in p["cells"]:
					check(not owner.has(c), "%s%s part overlap %s" % [id,suffix,c])
					owner[c] = true
			for loc in Location.COUNT:
				check(not m.parts_at(loc).is_empty(), "%s%s missing %s" % [id,suffix,Location.code(loc)])