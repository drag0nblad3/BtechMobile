class_name VxIntegrity
extends RefCounted
## Conservative topology repair after the FINAL raster/ownership pass.
## Never weld independent moving parts or seal authored ports and voids.

const GAP := 3
const RIG_GAP := 3
const SEARCH_LIMIT := 30000
const DIRS: Array[Vector3i] = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP,
		Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]


static func components(cells: Dictionary) -> Array[Dictionary]:
	var remaining := {}
	for c: Vector3i in cells:
		remaining[c] = true
	var groups: Array[Dictionary] = []
	while not remaining.is_empty():
		var seed: Vector3i = remaining.keys()[0]
		remaining.erase(seed)
		var group: Dictionary = {}
		group[seed] = true
		var queue: Array[Vector3i] = [seed]
		var index := 0
		while index < queue.size():
			var c: Vector3i = queue[index]
			index += 1
			for delta: Vector3i in DIRS:
				var neighbor := c + delta
				if remaining.has(neighbor):
					remaining.erase(neighbor)
					group[neighbor] = true
					queue.append(neighbor)
		groups.append(group)
	groups.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.size() > b.size())
	return groups


static func repair(m: VxModel, recipe: Dictionary = {}) -> Dictionary:
	var report := {"before": 0, "after": 0, "rejoined": 0,
			"joint_contacts": 0, "added": 0, "empty_parts": 0,
			"weak_joint_contacts": 0, "mass_reinforced": 0,
			"weak_joint_parts": []}
	var owned := {}
	for p: Dictionary in m.parts:
		for c: Vector3i in p["cells"]:
			owned[c] = p["name"]
	var n := maxi(1, m.detail)
	var voids := _authored_voids(recipe, n)
	var muzzle_guard := _muzzle_guard(m, n)
	for p: Dictionary in m.parts:
		var cells: Dictionary = p["cells"]
		var groups := components(cells)
		if groups.is_empty():
			report["empty_parts"] += 1
			continue
		report["before"] += groups.size() - 1
		var main: Dictionary = groups[0]
		# Tiny fragments may cross a short cavity; substantial modules get
		# only a one- or two-cell local stitch, never a sweeping support bar.
		# Glazing and emissive details must remain separate pieces.
		if _optical_detail(cells, m):
			continue
		var cap := mini(18 * n * n * n, maxi(2 * n * n * n, floori(main.size() * 0.06)))
		for i in range(1, groups.size()):
			var island: Dictionary = groups[i]
			var gap := GAP * n if island.size() <= cap else 2 * n
			var route := _path(island.keys(), main, owned, voids, muzzle_guard, gap)
			if route.is_empty():
				continue
			for c: Vector3i in route:
				cells[c] = _structure(m)
				owned[c] = p["name"]
				main[c] = true
			for c: Vector3i in island:
				main[c] = true
			report["added"] += route.size()
			report["rejoined"] += 1

	# Only explicit joints get a parent-contact bridge, not decorative panels.
	for p: Dictionary in m.parts:
		if String(p.get("joint", "")).is_empty() or String(p.get("parent", "")).is_empty():
			continue
		var parent: Dictionary = m.part(String(p["parent"]))
		if parent.is_empty() or p["cells"].is_empty() or parent["cells"].is_empty():
			continue
		var initial_patch := _solid_contact(p["cells"], parent["cells"], n)
		if initial_patch["strong"]:
			continue
		if int(initial_patch["area"]) == 0:
			var parent_cell := _nearest(parent["cells"], Vector3i(p["pivot"]))
			var child_cell := _nearest(p["cells"], parent_cell)
			var route := _path([child_cell], parent["cells"], owned, voids, muzzle_guard, 2 * n)
			if not route.is_empty():
				for c: Vector3i in route:
					p["cells"][c] = _structure(m)
					owned[c] = p["name"]
				report["added"] += route.size()
				report["joint_contacts"] += 1
		# A one-cell touch is not load-bearing. Widen the existing seam on
		# the moving child only; refuse voids, barrels and other owners.
		var reinforced := _reinforce_joint_mass(p, parent, owned, voids,
				muzzle_guard, n, _structure(m))
		report["mass_reinforced"] += reinforced
		report["added"] += reinforced
		var final_contact := _solid_contact(p["cells"], parent["cells"], n)
		if not final_contact["strong"]:
			report["weak_joint_contacts"] += 1
			report["weak_joint_parts"].append({"part": p["name"],
					"parent": parent["name"], "joint": p["joint"],
					"face_patch": final_contact["patch"],
					"backed_patch": final_contact["backed_patch"],
					"needed": final_contact["needed"],
					"depth_needed": final_contact["depth_needed"]})

	# The actual floating-island requirement is measured on rigid assemblies.
	# Join only very close unsupported geometry, after articulation ownership
	# and part-local repairs have settled.
	var rigid_fix := _repair_rigid_assemblies(m, owned, voids, muzzle_guard, n)
	report["rig_rejoined"] = rigid_fix["rejoined"]
	report["rig_added"] = rigid_fix["added"]
	report["added"] += rigid_fix["added"]
	# A tiny detached chip is not a viable armor plate or load-bearing frame.
	# When safe routing cannot attach it without sealing a real cavity, remove
	# only the small isolated fragment rather than leave a floating voxel.
	# This happens AFTER joint/socket repairs and never modifies another part.
	var pruned_orphans := 0
	for p: Dictionary in m.parts:
		var groups := components(p["cells"])
		for i in range(1, groups.size()):
			var orphan: Dictionary = groups[i]
			if orphan.size() > 12 * n * n * n:
				continue
			for c: Vector3i in orphan:
				p["cells"].erase(c)
				owned.erase(c)
				pruned_orphans += 1
	report["pruned_orphan_voxels"] = pruned_orphans
	var residual := {}
	for p: Dictionary in m.parts:
		var groups := components(p["cells"])
		var count := maxi(0, groups.size() - 1)
		report["after"] += count
		if count > 0:
			var sizes := []
			for i in range(1, groups.size()):
				sizes.append(groups[i].size())
			residual[p["name"]] = {"count": count, "sizes": sizes,
					"main": groups[0].size(), "parent": p.get("parent", ""),
					"joint": p.get("joint", ""), "loc": p.get("loc", -1)}
	report["residual_parts"] = residual
	# The visual model can contain several connected sub-meshes within one
	# damage location. Evaluate real, unsupported islands by their *rigid*
	# assembly rather than treating each armor panel as an island.
	var rigid := rigid_components(m)
	report["rig_islands"] = rigid["unanchored"]
	report["rig_groups"] = rigid["groups"]
	var assembled := physical_components(m)
	report["floating_islands"] = assembled["islands"]
	report["floating_groups"] = assembled["groups"]
	return report


## Geometrically unsupported fragments in the intact assembled 'Mech.
## This is the strict floating-island metric. Keep it separate from the more
## conservative per-rig diagnostic, which also records intentionally separated
## armor plates that share physical support through another articulated part.
static func physical_components(m: VxModel) -> Dictionary:
	var occupied := {}
	for p: Dictionary in m.parts:
		for c: Vector3i in p["cells"]:
			occupied[c] = true
	var groups := components(occupied)
	if groups.size() <= 1:
		return {"islands": 0, "groups": []}
	var sizes := []
	for i in range(1, groups.size()):
		sizes.append(groups[i].size())
	return {"islands": groups.size()-1, "groups": sizes}


## A rigid frame includes non-jointed children. A single cannon hand may
## occupy several subparts, all sharing one IK pivot. Join small gaps inside
## THAT frame; never make a bridge from one articulated limb to another.
static func _repair_rigid_assemblies(m: VxModel, owned: Dictionary,
		voids: Array[Dictionary], guard: Dictionary, n: int) -> Dictionary:
	var rigs: Dictionary = {}
	for p: Dictionary in m.parts:
		var root := _rig_root(m, p)
		if not rigs.has(root):
			rigs[root] = {}
		for c: Vector3i in p["cells"]:
			rigs[root][c] = true
	var report := {"rejoined": 0, "added": 0}
	var optical_names: Dictionary = {}
	for p: Dictionary in m.parts:
		if _optical_detail(p["cells"], m):
			optical_names[p["name"]] = true
	for root: String in rigs:
		var groups := components(rigs[root])
		if groups.size() < 2:
			continue
		var solid: Dictionary = groups[0]
		for i in range(1, groups.size()):
			var island: Dictionary = groups[i]
			if _all_optical(island, optical_names, owned):
				continue
			var route := _path(island.keys(), solid, owned, voids, guard, RIG_GAP * n)
			if route.is_empty():
				continue
			# First step is face-adjacent to the orphan component; attaching
			# it to that component's owning part preserves the rig transform.
			var attaching_part: Dictionary = {}
			for d: Vector3i in DIRS:
				var near: Vector3i = route[0] + d
				if island.has(near):
					attaching_part = m.part(String(owned[near]))
					break
			if attaching_part.is_empty():
				continue
			for c: Vector3i in route:
				attaching_part["cells"][c] = _structure(m)
				owned[c] = attaching_part["name"]
				solid[c] = true
			for c: Vector3i in island:
				solid[c] = true
			report["added"] += route.size()
			report["rejoined"] += 1
	return report


static func _all_optical(group: Dictionary, optical_names: Dictionary,
		owned: Dictionary) -> bool:
	for c: Vector3i in group:
		if not optical_names.has(owned[c]):
			return false
	return true


## A parent with no articulated joint inherits the ancestor's rigid frame.
## Actual hinges (shoulder, knee, hip, ankle, hock) begin a new assembly.
static func _rig_root(m: VxModel, p: Dictionary) -> String:
	var current: Dictionary = p
	var seen := {}
	while not current.is_empty():
		var name: String = current["name"]
		if seen.has(name):
			return name
		seen[name] = true
		var parent: String = current.get("parent", "")
		if parent.is_empty() or not String(current.get("joint", "")).is_empty():
			return name
		current = m.part(parent)
	return String(p["name"])


## Check physical occupancy across all subparts of each rigid assembly.
## Disjoint optical panels touching a common skull are not flying debris.
static func rigid_components(m: VxModel) -> Dictionary:
	var rigs := {}
	for p: Dictionary in m.parts:
		var root := _rig_root(m, p)
		if not rigs.has(root):
			rigs[root] = {}
		for c: Vector3i in p["cells"]:
			rigs[root][c] = true
	var details := {}
	var count := 0
	for root: String in rigs:
		var groups := components(rigs[root])
		if groups.size() <= 1:
			continue
		var sizes := []
		for i in range(1, groups.size()):
			sizes.append(groups[i].size())
		count += groups.size() - 1
		details[root] = sizes
	return {"unanchored": count, "groups": details}


## Do not bridge optical planes or independent cockpit glow/window pieces.
static func _optical_detail(cells: Dictionary, m: VxModel) -> bool:
	var optical := {}
	for key in ["window", "glass", "glow", "recess"]:
		if m._mat.has(key):
			optical[m._mat[key]] = true
	if optical.is_empty():
		return false
	for id: int in cells.values():
		if not optical.has(id):
			return false
	return true


static func _structure(m: VxModel) -> int:
	for key in ["joint", "frame", "inside", "structure"]:
		if m._mat.has(key):
			return int(m._mat[key])
	for i in m.roles.size():
		if m.roles[i] == "structure":
			return i
	return 0


## A solid joint needs a contiguous contact face patch, not just one
## coincident cube or a few isolated touching corners. Normalize the
## required area by resolution and by the smaller component's size.
static func _solid_contact(child: Dictionary, parent: Dictionary, n: int = 1) -> Dictionary:
	var face: Dictionary = {}
	var backed: Dictionary = {}
	for c: Vector3i in child:
		for d: Vector3i in DIRS:
			if parent.has(c + d):
				face[c] = true
				# The face must connect to at least one voxel of physical
				# interior immediately behind it, not a one-layer skin.
				if child.has(c - d):
					backed[c] = true
				break
	var patch := 0
	var backed_patch := 0
	if not face.is_empty():
		patch = components(face)[0].size()
	if not backed.is_empty():
		backed_patch = components(backed)[0].size()
	var scale := maxi(1, n)
	var required := mini(12 * scale * scale,
			maxi(4 * scale * scale, mini(child.size(), parent.size()) / 12))
	var depth_needed := mini(required, maxi(2 * scale * scale, required / 2))
	return {"strong": patch >= required and backed_patch >= depth_needed,
			"patch": patch, "backed_patch": backed_patch,
			"area": face.size(), "needed": required, "depth_needed": depth_needed}

## Extend the moving part's existing joint socket into a *broad* collar.
## Never modify the stationary parent, authored subtractive geometry,
## muzzle corridors, or another articulated part's ownership.
static func _reinforce_joint_mass(child: Dictionary, parent: Dictionary,
		owned: Dictionary, voids: Array[Dictionary], guard: Dictionary,
		n: int, mat: int) -> int:
	var cvox: Dictionary = child["cells"]
	var pvox: Dictionary = parent["cells"]
	if _solid_contact(cvox, pvox, n)["strong"]:
		return 0
	var socket := _nearest(cvox, Vector3i(child["pivot"]))
	var limit := maxi(2, 2 * n)
	var added := 0
	for attempt in range(3):
		var staged: Dictionary = {}
		for c: Vector3i in cvox:
			if absi(c.x-socket.x) + absi(c.y-socket.y) + absi(c.z-socket.z) > 4 * n + 3:
				continue
			for d: Vector3i in DIRS:
				var v: Vector3i = c + d
				if owned.has(v) or staged.has(v) or guard.has(v):
					continue
				if _in_void(v, voids):
					continue
				if absi(v.x-socket.x) + absi(v.y-socket.y) + absi(v.z-socket.z) > limit + n:
					continue
				var contact := false
				for side: Vector3i in DIRS:
					if pvox.has(v + side):
						contact = true
						break
				if contact:
					staged[v] = true
		if staged.is_empty():
			break
		for v: Vector3i in staged:
			cvox[v] = mat
			owned[v] = child["name"]
			added += 1
		# Back the broad contact patch with an actual second structural
		# layer. A contact-only veneer over a one-voxel neck is not a joint.
		var supported: Dictionary = {}
		for c: Vector3i in cvox:
			if absi(c.x-socket.x) + absi(c.y-socket.y) + absi(c.z-socket.z) > 4 * n + 3:
				continue
			for d: Vector3i in DIRS:
				if not pvox.has(c + d):
					continue
				var behind: Vector3i = c - d
				if cvox.has(behind) or owned.has(behind) or guard.has(behind):
					continue
				if _in_void(behind, voids):
					continue
				supported[behind] = true
		for c: Vector3i in supported:
			cvox[c] = mat
			owned[c] = child["name"]
			added += 1
		if _solid_contact(cvox, pvox, n)["strong"]:
			break
	return added


static func _touch(a: Dictionary, b: Dictionary) -> bool:
	for c: Vector3i in a:
		for d: Vector3i in DIRS:
			if b.has(c + d):
				return true
	return false


static func _nearest(cells: Dictionary, point: Vector3i) -> Vector3i:
	var closest := point
	var best := 2147483647
	for c: Vector3i in cells:
		var dist := absi(c.x-point.x) + absi(c.y-point.y) + absi(c.z-point.z)
		if dist < best:
			best = dist
			closest = c
	return closest


static func _path(seeds: Array, target: Dictionary, owned: Dictionary,
		voids: Array[Dictionary], guard: Dictionary, max_gap: int) -> Array[Vector3i]:
	var queue: Array[Vector3i] = []
	var dist: Dictionary = {}
	var prev: Dictionary = {}
	# Work only from the source boundary nearest the target's bounds.
	# A big 100k-cell launcher may have >30k exposed cells; enqueuing all
	# of them previously exhausted the visit budget before any routing.
	var lo := Vector3i(2147483647, 2147483647, 2147483647)
	var hi := Vector3i(-2147483647, -2147483647, -2147483647)
	for c: Vector3i in target:
		lo = Vector3i(mini(lo.x,c.x), mini(lo.y,c.y), mini(lo.z,c.z))
		hi = Vector3i(maxi(hi.x,c.x), maxi(hi.y,c.y), maxi(hi.z,c.z))
	var closest := 2147483647
	for c: Vector3i in seeds:
		closest = mini(closest, _distance_to_bounds(c, lo, hi))
	var candidates: Array[Vector3i] = []
	for c: Vector3i in seeds:
		if _distance_to_bounds(c, lo, hi) <= closest + 1:
			candidates.append(c)
	# Retain a distributed sample when the bounding boxes overlap and
	# thousands of candidates tie. Never spend all visits on seed points.
	var stride := maxi(1, ceili(float(candidates.size()) / 2048.0))
	for i in range(0, candidates.size(), stride):
		var c: Vector3i = candidates[i]
		queue.append(c)
		dist[c] = 0
	var head := 0
	while head < queue.size() and head < SEARCH_LIMIT:
		var c: Vector3i = queue[head]
		head += 1
		if int(dist[c]) >= max_gap:
			continue
		for d: Vector3i in DIRS:
			var step := c + d
			if target.has(step):
				var route: Array[Vector3i] = []
				var at := c
				while prev.has(at):
					route.append(at)
					at = prev[at]
				route.reverse()
				return route
			if dist.has(step) or owned.has(step) or guard.has(step):
				continue
			if _in_void(step, voids):
				continue
			dist[step] = int(dist[c]) + 1
			prev[step] = c
			queue.append(step)
	return []


static func _distance_to_bounds(c: Vector3i, lo: Vector3i, hi: Vector3i) -> int:
	var dx := maxi(0, maxi(lo.x-c.x, c.x-hi.x))
	var dy := maxi(0, maxi(lo.y-c.y, c.y-hi.y))
	var dz := maxi(0, maxi(lo.z-c.z, c.z-hi.z))
	return dx + dy + dz


static func _in_void(c: Vector3i, voids: Array[Dictionary]) -> bool:
	for item: Dictionary in voids:
		var lo: Vector3i = item["lo"]
		var hi: Vector3i = item["hi"]
		if c.x >= lo.x and c.x <= hi.x and c.y >= lo.y and c.y <= hi.y \
				and c.z >= lo.z and c.z <= hi.z:
			return true
	return false


static func _authored_voids(recipe: Dictionary, n: int) -> Array[Dictionary]:
	var voids: Array[Dictionary] = []
	var by_name := {}
	for p: Dictionary in recipe.get("parts", []):
		by_name[p.get("name", "")] = p
	for p: Dictionary in recipe.get("parts", []):
		var mirrored := p.has("mirror")
		var source: Dictionary = by_name.get(p["mirror"], {}) if mirrored else p
		for s: Dictionary in source.get("shapes", []) + p.get("add", []):
			if not s.has("erase"):
				continue
			var lo := Vector3i(s["erase"][0][0], s["erase"][0][1], s["erase"][0][2])
			var hi := Vector3i(s["erase"][1][0], s["erase"][1][1], s["erase"][1][2])
			if mirrored:
				var low_x := lo.x
				lo.x = -hi.x - 1
				hi.x = -low_x - 1
			voids.append({"lo": lo * n, "hi": (hi + Vector3i.ONE) * n - Vector3i.ONE})
	return voids


static func _muzzle_guard(m: VxModel, n: int) -> Dictionary:
	var guard := {}
	for points: Array in m.muzzles.values():
		for point: Vector3 in points:
			var c := Vector3i(floori(point.x), floori(point.y), floori(point.z))
			for x in range(c.x - n, c.x + n + 1):
				for y in range(c.y - n, c.y + n + 1):
					for z in range(c.z - 2 * n, c.z + n + 1):
						guard[Vector3i(x, y, z)] = true
	return guard
