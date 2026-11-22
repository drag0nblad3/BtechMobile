class_name BattleCodec
extends RefCounted
## Save-safe, JSON-compatible snapshot of rules objects and typed keys.
## Only BattleFields objects can be constructed on read.

static func pack(v: Variant) -> Variant:
	match typeof(v):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return v
		TYPE_STRING_NAME:
			return String(v)
		TYPE_VECTOR2:
			return {"$": "v2", "x": v.x, "y": v.y}
		TYPE_VECTOR3:
			return {"$": "v3", "x": v.x, "y": v.y, "z": v.z}
		TYPE_VECTOR2I:
			return {"$": "v2i", "x": v.x, "y": v.y}
		TYPE_VECTOR3I:
			return {"$": "v3i", "x": v.x, "y": v.y, "z": v.z}
		TYPE_COLOR:
			return {"$": "color", "hex": "#" + v.to_html(true)}
		TYPE_ARRAY:
			var out := []
			for item in v:
				out.append(pack(item))
			return {"$": "array", "items": out}
		TYPE_DICTIONARY:
			var pairs := []
			for key in v:
				pairs.append([pack(key), pack(v[key])])
			return {"$": "dictionary", "items": pairs}
		TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY:
			return {"$": "packed", "kind": typeof(v), "items": pack(Array(v))}
		TYPE_OBJECT:
			if v is UnitDef:
				return {"$": "unit_def", "id": v.id}
			if v is WeaponDef:
				# Asset weapons are synthesized from a card, not in the weapon catalog.
				if String(v.id).begins_with("asset_") or String(v.id).begins_with("ba_"):
					var inline := {}
					for n: String in BattleFields.names(v):
						inline[n] = pack(v.get(n))
					return {"$": "object", "class": "WeaponDef", "properties": inline}
				return {"$": "weapon_def", "id": v.id}
			if v is TerrainType:
				return {"$": "terrain", "id": v.id}
			if v is BuildingType:
				return {"$": "building_type", "id": v.id}
			var names := BattleFields.names(v)
			if names.is_empty():
				push_error("Battle save: unsupported class " + str(v.get_class()))
				return null
			var properties := {}
			for n: String in names:
				properties[n] = pack(v.get(n))
			return {"$": "object", "class": v.get_script().get_global_name(),
					"properties": properties}
	push_error("Battle save: unsupported Variant type %d" % typeof(v))
	return null


static func unpack(v: Variant, units: UnitDb, terrain: TerrainDb) -> Variant:
	if not (v is Dictionary) or not v.has("$"):
		return v
	match String(v["$"]):
		"v2": return Vector2(float(v["x"]), float(v["y"]))
		"v3": return Vector3(float(v["x"]), float(v["y"]), float(v["z"]))
		"v2i": return Vector2i(int(v["x"]), int(v["y"]))
		"v3i": return Vector3i(int(v["x"]), int(v["y"]), int(v["z"]))
		"color": return Color(String(v["hex"]))
		"array":
			var a := []
			for item in v["items"]:
				a.append(unpack(item, units, terrain))
			return a
		"dictionary":
			var d := {}
			for pair: Array in v["items"]:
				d[unpack(pair[0], units, terrain)] = unpack(pair[1], units, terrain)
			return d
		"packed":
			var a: Array = unpack(v["items"], units, terrain)
			match int(v["kind"]):
				TYPE_PACKED_STRING_ARRAY: return PackedStringArray(a)
				TYPE_PACKED_INT32_ARRAY: return PackedInt32Array(a)
				TYPE_PACKED_INT64_ARRAY: return PackedInt64Array(a)
				TYPE_PACKED_FLOAT32_ARRAY: return PackedFloat32Array(a)
				TYPE_PACKED_FLOAT64_ARRAY: return PackedFloat64Array(a)
			return a
		"unit_def": return units.get_def(String(v["id"]))
		"weapon_def": return units.weapons.get_def(String(v["id"]))
		"terrain": return terrain.get_type(String(v["id"]))
		"building_type": return terrain.buildings.get(String(v["id"]))
		"object":
			var props: Dictionary = v["properties"]
			var class_tag: String = v["class"]
			var obj := BattleFields.create(class_tag, props, units, terrain)
			if obj == null:
				push_error("Battle save: unknown class or missing catalog entry " + class_tag)
				return null
			# Loading Conditions while map is null prevents it from overwriting
			# ice, mud or snow changes already serialized on the map.
			if obj is GameState:
				obj.conditions = unpack(props["conditions"], units, terrain)
				obj.map = unpack(props["map"], units, terrain)
			for n: String in BattleFields.names(obj):
				if not props.has(n):  # forward-compatible optional fields
					continue
				if obj is GameState and n in ["map", "conditions"]:
					continue
				var value: Variant = unpack(props[n], units, terrain)
				if obj.get(n) is Array and value is Array:
					var current: Array = obj.get(n)
					current.assign(value)  # retain Array[int] / Array[Unit] types
				else:
					obj.set(n, value)
			return obj
	return null
