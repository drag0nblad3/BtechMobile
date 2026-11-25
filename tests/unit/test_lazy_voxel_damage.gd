extends TestCase
## Cosmetic order generation is lazy but must retain the original seed and
## traversal, including independent front/rear/structure regions.


func _fixture() -> VxModel:
	var m := VxModel.new()
	m.id = "lazy_damage_fixture"
	m.roles.assign(["armor", "structure"])
	m.parts.append({"name": "body", "loc": Location.CT, "cells": {
		Vector3i(0, 0, -1): 0, Vector3i(0, 1, -1): 0,
		Vector3i(0, 0, 1): 0, Vector3i(0, 0, 0): 1}})
	return m


func test_intact_model_requires_no_crater_orders() -> void:
	var m := _fixture()
	var d := VxDamage.new(m, {})
	check(m.damage_orders.is_empty(), "no precomputation during model build")
	d.show_location(Location.CT, 0.0, 0.0, 0.0, false)
	check(m.damage_orders.is_empty(), "undamaged model does no crater work")
	d.show_location(Location.CT, 0.5, 0.0, 0.0, false)
	check_eq(m.damage_orders.size(), 1)
	check(m.damage_orders.has("%d:a" % Location.CT))
	var other := VxDamage.new(m, {})
	check_eq(other.order_size(Location.CT, "a"), 2)
	check_eq(m.damage_orders.size(), 1, "shared immutable cached order")


func test_lazy_craters_equal_seeded_eager_sequence() -> void:
	var m := _fixture()
	var d := VxDamage.new(m, {})
	var front := [["body", Vector3i(0, 0, -1)], ["body", Vector3i(0, 1, -1)]]
	var key := "%d:a" % Location.CT
	var expected := d._craters(front, key)
	check_eq(d._order(Location.CT, "a"), expected)
	check_eq(d.order_size(Location.CT, "r"), 1)
	check_eq(d.order_size(Location.CT, "s"), 1)
	var fresh := VxDamage.new(_fixture(), {})
	check_eq(fresh._order(Location.CT, "a"), expected, "cold load reproduces same scars")
