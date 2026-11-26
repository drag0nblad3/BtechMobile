class_name UnitFavorites
extends RefCounted
## Player-local design bookmarks, never part of a force, campaign or rules state.

const PATH := "user://unit_favorites.cfg"
static var _loaded := false
static var _ids: Dictionary = {}
static var revision := 0


static func read(path: String) -> Dictionary:
	var cfg := ConfigFile.new()
	var result := {}
	if cfg.load(path) == OK:
		var stored: Variant = cfg.get_value("units", "favorites", [])
		if stored is Array:
			for id: Variant in stored:
				if id is String and not String(id).is_empty():
					result[id] = true
	return result


static func write(path: String, ids: Dictionary) -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("units", "favorites", ids.keys())
	return cfg.save(path)


static func _load() -> void:
	if not _loaded:
		_ids = read(PATH)
		_loaded = true


static func has(id: String) -> bool:
	_load()
	return _ids.has(id)


static func toggle(id: String) -> void:
	if id.is_empty():
		return
	_load()
	if _ids.has(id):
		_ids.erase(id)
	else:
		_ids[id] = true
	revision += 1
	if write(PATH, _ids) != OK:
		push_warning("Unable to save unit favorites")


## Stable display-only partition: never reorder the source array or action IDs.
## A supplied dictionary allows tests to avoid touching player preferences.
static func indices(items: Array, id_of: Callable, favorites: Variant = null) -> Array[int]:
	_load()
	var ids: Dictionary = _ids if favorites == null else favorites
	var first: Array[int] = []
	var rest: Array[int] = []
	for i in items.size():
		if ids.has(id_of.call(items[i])):
			first.append(i)
		else:
			rest.append(i)
	first.append_array(rest)
	return first


static func prioritized(items: Array, id_of: Callable, favorites: Variant = null) -> Array:
	var result := []
	for i in indices(items, id_of, favorites):
		result.append(items[i])
	return result


static func design_id(d: UnitDef) -> String:
	return d.id


static func first_favorite(variants: Array) -> String:
	for d: UnitDef in variants:
		if has(d.id):
			return d.id
	return ""


static func caption(id: String, title: String) -> String:
	return ("★ " if has(id) else "") + title


static func style(button: Button, id: String) -> void:
	var active := not id.is_empty() and has(id)
	button.text = "★" if active else "☆"
	button.disabled = id.is_empty()
	button.tooltip_text = "Remove from favorites" if active else "Add to favorites"
	UiSkin.button(button, "selected" if active else "subtle")


static func button(parent: Control, id: String, redraw: Callable) -> Button:
	var b := UiKit.button(parent, "", func():
		toggle(id)
		if redraw.is_valid():
			redraw.call(), Vector2(48, 48), "subtle")
	b.name = "FavoriteUnit"
	b.set_meta("unit_id", id)
	style(b, id)
	return b
