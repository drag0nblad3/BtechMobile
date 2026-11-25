class_name ReplayUnitViews
extends RefCounted
## Reuses unchanged model geometry; rebuilds changed damage records so
## backwards seeks restore missing limbs, paint and armor correctly.


static func appearance(u: Unit) -> Array:
	return [u.def.id, u.side, u.armor.duplicate(), u.rear_armor.duplicate(),
		u.structure.duplicate(), u.destroyed]


static func sync(layer: UnitsLayer, state: GameState) -> void:
	var keep := {}
	for u: Unit in state.all_units():
		keep[u.id] = true
		var v: UnitView = layer.views.get(u.id)
		var key := appearance(u)
		if v != null and v.get_meta("replay_appearance", []) != key:
			layer.remove_child(v)
			v.queue_free()
			v = null
		if v == null:
			v = UnitView.new()
			layer.add_child(v)
			v.setup(u, state.map)
			v.set_meta("replay_appearance", key)
			layer.views[u.id] = v
		else:
			var old := v.unit
			var moved := old.coord != u.coord or old.facing != u.facing or old.prone != u.prone \
					or old.on_roof != u.on_roof or old.on_bridge != u.on_bridge
			v.unit = u
			v.map = state.map
			if moved:
				v.snap_to_state()
		v.set_field_visible(not state.reserves.has(u) and not state.waiting.has(u)
				and not state.mission.exited.has(u.id))
	for id: int in layer.views.keys():
		if not keep.has(id):
			var v: UnitView = layer.views[id]
			layer.remove_child(v)
			v.queue_free()
			layer.views.erase(id)
