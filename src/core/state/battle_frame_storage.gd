class_name BattleFrameStorage
extends RefCounted
## Immutable packed snapshots in memory; lossless property deltas on disk.
## Public replay consumers still receive the original full-frame shape.

const CHECKPOINT_INTERVAL := 32
const UNIT_LISTS := ["units", "hidden", "reserves", "waiting"]


static func share(current: Dictionary, previous: Dictionary) -> Dictionary:
	var props: Dictionary = current.get("properties", {})
	var old: Dictionary = previous.get("properties", {})
	for key: String in props:
		if not old.has(key):
			continue
		if props[key] == old[key]:
			props[key] = old[key]
		elif key in UNIT_LISTS:
			var items: Array = props[key]["items"]
			var old_items: Array = old[key]["items"]
			var by_id := {}
			for item: Dictionary in old_items:
				by_id[item["properties"]["id"]] = item
			for i in items.size():
				var prior: Dictionary = by_id.get(items[i]["properties"]["id"], {})
				if items[i] == prior:
					items[i] = prior
	return current


## Reuses unchanged values while keeping every frame independently seekable.
## The on-disk delta replaces changed properties; it never changes a base.
static func encode(frames: Array) -> Array:
	var out := []
	var previous := {}
	for i in frames.size():
		var frame: Dictionary = frames[i]
		var state: Dictionary = frame.get("state", {})
		var copy := frame.duplicate()
		if i % CHECKPOINT_INTERVAL != 0 and _snapshot(state) and _snapshot(previous):
			var changes := {}
			var props: Dictionary = state["properties"]
			var old: Dictionary = previous["properties"]
			# An allowlist change is represented as a full checkpoint.
			if props.keys() == old.keys():
				for key: String in props:
					if props[key] != old[key]:
						changes[key] = props[key]
				copy.erase("state")
				copy["state_delta"] = changes
		out.append(copy)
		previous = state
	return out


static func decode(frames: Array) -> Array:
	var out := []
	var previous := {}
	for frame: Dictionary in frames:
		var copy := frame.duplicate()
		if copy.has("state_delta"):
			if not _snapshot(previous) or not copy["state_delta"] is Dictionary:
				return []
			var state := previous.duplicate()
			var props: Dictionary = previous["properties"].duplicate()
			for key: String in copy["state_delta"]:
				if not props.has(key):
					return []
				props[key] = copy["state_delta"][key]
			state["properties"] = props
			copy["state"] = share(state, previous)
			copy.erase("state_delta")
		elif _snapshot(copy.get("state", {})):
			copy["state"] = share(copy["state"], previous)
		previous = copy.get("state", {})
		out.append(copy)
	return out


static func _snapshot(value: Variant) -> bool:
	return value is Dictionary and value.get("$") == "object" and value.get("class") == "GameState" and value.get("properties") is Dictionary
