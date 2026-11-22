class_name VxArtQuality
extends RefCounted
## Source-preserving, geometry-first visual refinement for the voxel catalog.
## This adjusts primary cross-section polygons BEFORE subdivision. It never
## relocates pivots, guns, missile bores, muzzle coordinates, or animation joints.
## Four passes: waist/chest depth, shoulder clearance, arm/weapon separation,
## lower-leg/head scale. Broad carapaces and unusual cockpit silhouettes survive.

const REVISION := "silhouette-and-weapon-clarity-20261121"
const AVIAN := ["marauder", "timber_wolf", "raven", "cicada", "fire_moth",
	"ice_ferret", "kit_fox", "mad_dog", "shadow_cat", "stormcrow", "piranha",
	"grendel", "adder", "locust", "flea", "spider", "bushwacker", "stalker"]
const WIDE := ["king_crab", "atlas", "annihilator", "kodiak", "dire_wolf",
	"nightstar", "longbow", "turkina", "goliath", "scorpion", "tarantula",
	"thunder_stallion"]
const SCOUT := ["wasp", "stinger", "flea", "spider", "locust", "mercury",
	"mongoose", "pack_hunter", "raven", "ice_ferret", "kit_fox",
	"fire_moth", "firefly", "adder", "cicada", "hollander"]
const QUADS := ["goliath", "scorpion", "tarantula", "thunder_stallion"]
const SPECIAL_HEAD := ["atlas", "jenner", "wolverine", "king_crab",
	"urbanmech", "marauder", "timber_wolf"]


static func apply(raw: Dictionary) -> Dictionary:
	# Newly sculpted files may already contain this specific pass baked into JSON.
	if raw.get("art_quality_revision", "") == REVISION:
		return raw
	if not raw.has("parts"):
		return raw
	var d := raw.duplicate(true)
	var mech_id: String = String(d.get("id", "")).trim_suffix("_shape")
	var kind := "humanoid"
	if mech_id in QUADS:
		kind = "quad"
	elif mech_id in WIDE:
		kind = "wide"
	elif mech_id in AVIAN:
		kind = "avian"
	elif mech_id in SCOUT:
		kind = "scout"

	for part: Dictionary in d["parts"]:
		if part.has("mirror"):
			continue
		var part_name: String = part.get("name", "")
		for shape: Dictionary in part.get("shapes", []):
			if not shape.has("loft"):
				continue
			var loft: Dictionary = shape["loft"]
			if loft.get("axis", "y") != "y":
				continue
			var sections: Array = loft.get("sections", [])
			for idx in sections.size():
				var sec: Dictionary = sections[idx]
				var poly: Array = sec.get("polygon", [])
				if poly.is_empty():
					continue
				var min_x := INF
				var max_x := -INF
				var min_z := INF
				var max_z := -INF
				for point: Array in poly:
					min_x = minf(min_x, float(point[0]))
					max_x = maxf(max_x, float(point[0]))
					min_z = minf(min_z, float(point[1]))
					max_z = maxf(max_z, float(point[1]))
				var cx: float = (min_x + max_x) * 0.5
				var cz: float = (min_z + max_z) * 0.5
				var phase: float = float(idx) / float(maxi(sections.size() - 1, 1))
				var width: float = max_x - min_x
				var depth: float = max_z - min_z
				var fx := 1.0
				var fz := 1.0

				# Pass 1: remove slab waist and excess posterior torso volume.
				# Keep the mid-chest broad enough to preserve original identity.
				if part_name == "ct" and kind != "quad" and mech_id != "urbanmech":
					match kind:
						"wide":
							fx = 0.955 if phase < 0.26 else (0.958 if phase > 0.8 else 0.995)
						"avian":
							fx = 0.946 if phase < 0.29 else (0.925 if phase > 0.8 else 0.99)
						"scout":
							fx = 0.925 if phase < 0.3 else (0.91 if phase > 0.8 else 0.985)
						_:
							fx = 0.89 if phase < 0.27 else (0.935 if phase > 0.8 else 0.99)
					if depth > width * 1.18:
						fz = 0.94 if kind == "avian" else 0.955

				# Pass 2: clearer shoulder breaks, leaving inner mounting faces.
				elif part_name in ["lt", "rt"] and kind != "quad":
					fx = (0.87 if kind == "scout" else (0.89 if kind == "avian" else 0.93)) if phase > 0.45 else 0.975
					if depth > width * 1.35:
						fz = 0.94

				# Pass 3: reduce upper-arm armor behind the gun, but preserve
				# forward negative-z barrel geometry and physical muzzle cuts.
				elif part_name in ["la", "ra"] and kind != "quad":
					fx = (0.87 if kind == "avian" else (0.88 if kind == "scout" else 0.91)) if phase > 0.55 else 0.975
					fz = 0.85 if kind == "avian" else 0.90

				# Pass 4: narrow bloated shins, without moving hip/knee pivots.
				elif part_name.ends_with("_shin"):
					fx = (0.89 if kind == "scout" else 0.925) if phase > 0.25 and phase < 0.8 else 0.98
				elif part_name == "hd" and mech_id not in SPECIAL_HEAD and width > 6.0:
					fx = 0.94
				else:
					continue

				for point: Array in poly:
					var px: float = float(point[0])
					if not ((part_name == "lt" and px >= cx) or (part_name == "rt" and px <= cx)):
						point[0] = snappedf(cx + (px - cx) * fx, 0.01)
					var pz: float = float(point[1])
					if pz > cz and fz < 1.0:
						point[1] = snappedf(cz + (pz - cz) * fz, 0.01)

	# A previously colliding weapon mount is never allowed to share voxels with
	# a moving shoulder or torso. This is performed by VxModel after painting.
	d["exclusive_parts"] = true
	d["art_quality_revision"] = REVISION
	return d


## Assets are not smaller BattleMechs. Preserve long hulls, exposed tracks,
## wheel spacing, flight rotors and separate infantry weapon silhouettes.
## All asset edits remove mass; the 50,000 occupied-voxel cap is unchanged.
static func apply_asset(raw: Dictionary) -> Dictionary:
	if raw.get("art_quality_revision", "") == REVISION:
		return raw
	if not raw.has("parts"):
		return raw
	var d := raw.duplicate(true)
	var typ: String = d.get("asset_kind", "")
	var move: String = d.get("motive", "")
	for part: Dictionary in d["parts"]:
		var part_name: String = part.get("name", "")
		for shape: Dictionary in part.get("shapes", []):
			if shape.has("loft") and part_name in ["hull", "fuselage", "turret", "roof"]:
				var loft: Dictionary = shape["loft"]
				if loft.get("axis", "y") != "y":
					continue
				var sections: Array = loft.get("sections", [])
				for idx in sections.size():
					# Maintain full lower hull contact with tracks or hover skirt.
					var phase: float = float(idx) / float(maxi(sections.size()-1, 1))
					if phase < 0.28:
						continue
					var sec: Dictionary = sections[idx]
					var poly: Array = sec.get("polygon", [])
					if poly.is_empty():
						continue
					var min_x := INF
					var max_x := -INF
					var min_z := INF
					var max_z := -INF
					for point: Array in poly:
						min_x = minf(min_x, float(point[0]))
						max_x = maxf(max_x, float(point[0]))
						min_z = minf(min_z, float(point[1]))
						max_z = maxf(max_z, float(point[1]))
					var cx: float = (min_x + max_x) * 0.5
					var cz: float = (min_z + max_z) * 0.5
					var fac := 0.94 if move == "h" else (0.96 if typ == "vtol" else 0.95)
					if part_name == "turret":
						fac = 0.91
					for point: Array in poly:
						point[0] = snappedf(cx + (float(point[0])-cx)*fac, 0.01)
						# Reduce high rear decking rather than shortening the
						# vehicle nose, weapon firing line or aviation tail.
						if move in ["t","w"] and float(point[1]) > cz:
							point[1] = snappedf(cz + (float(point[1])-cz)*0.96, 0.01)
			elif typ in ["infantry", "battle_armor"] and (
					part_name.begins_with("soldier") or part_name.begins_with("elemental")):
				if not shape.has("box") or shape.get("mat", "") != "armor":
					continue
				var a: Array = shape["box"][0]
				var z: Array = shape["box"][1]
				if int(z[0]) - int(a[0]) < 4 or int(z[1]) - int(a[1]) < 4:
					continue
				# A real polygonal waist/chest, not one rectangular body slab.
				var middle_y: int = (int(a[1]) + int(z[1])) / 2
				var x0: int = int(a[0])
				var x1: int = int(z[0])
				var z0: int = int(a[2])
				var z1: int = int(z[2])
				var waist: Array = [[x0+1,z0],[x1-1,z0],
					[x1-1,z1],[x0+1,z1]]
				var chest: Array = [[x0,z0],[x1,z0],
					[x1,z1],[x0,z1]]
				shape.erase("box")
				shape["loft"] = {"axis":"y","sections":[
					{"at":int(a[1]),"polygon":waist},
					{"at":middle_y,"polygon":chest},
					{"at":int(z[1]),"polygon":chest}]}
	d["exclusive_parts"] = true
	d["art_quality_revision"] = REVISION
	return d
