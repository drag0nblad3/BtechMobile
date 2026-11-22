extends TestCase
## Regression: the shape-first body-mass reduction pass reaches every previous
## editable LOD pair, and does NOT let high-detail contours drift from low.
const PRIOR := [
	"annihilator",
	"archer",
	"awesome",
	"banshee",
	"battlemaster",
	"black_knight",
	"blackjack",
	"bushwacker",
	"cataphract",
	"centurion",
	"cicada",
	"commando",
	"crab",
	"crusader",
	"cyclops",
	"dire_wolf",
	"dragon",
	"enforcer",
	"fire_moth",
	"firestarter",
	"flea",
	"gargoyle",
	"grasshopper",
	"griffin",
	"highlander",
	"jagermech",
	"javelin",
	"king_crab",
	"locust",
	"longbow",
	"mad_dog",
	"marauder",
	"mauler",
	"mist_lynx",
	"nightstar",
	"nova",
	"orion",
	"ostroc",
	"ostsol",
	"panther",
	"phoenix_hawk",
	"quickdraw",
	"raven",
	"rifleman",
	"shadow_cat",
	"shadow_hawk",
	"spider",
	"stalker",
	"stormcrow",
	"summoner",
	"thunderbolt",
	"timber_wolf",
	"trebuchet",
	"urbanmech",
	"vindicator",
	"warhammer",
	"warhawk"
]
const SPECIAL := ["atlas", "jenner", "wolverine"]


func test_prior_model_pair_pass_applied_to_both_lods() -> void:
	for id: String in PRIOR:
		var lo: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		var hi: Dictionary = JsonFile.read("res://data/voxels/%s.json" % id)
		check_eq(lo.get("art_revision", ""), "shape-first-slab-relief-v2-20261121",
			"%s shape model updated" % id)
		check_eq(lo.get("art_revision", ""), hi.get("art_revision", ""),
			"%s both LODs share same art revision" % id)
		var hist := {}
		for part: Dictionary in hi["parts"]:
			hist[part["name"]] = part
		for part: Dictionary in lo["parts"]:
			if part.has("mirror"):
				continue
			var high_part: Dictionary = hist.get(part["name"], {})
			check(not high_part.is_empty(), "%s %s has high-res counterpart" % [id, part["name"]])
			for i in part.get("shapes", []).size():
				if part["shapes"][i].has("loft") and high_part.get("shapes", []).size() > i:
					check_eq(part["shapes"][i]["loft"], high_part["shapes"][i].get("loft", {}),
						"%s %s primary silhouette unchanged by detail" % [id, part["name"]])


func test_atlas_jenner_wolverine_generated_source_pass() -> void:
	for id: String in SPECIAL:
		var src: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		check_eq(src.get("art_revision", ""), "sculpt-specific-slab-relief-v2-20261121")
		var hi: Dictionary = JsonFile.read("res://data/voxels/%s_voxel.json" % id)
		check(hi.get("source", "") != "", id + " retains generated sculpt source")