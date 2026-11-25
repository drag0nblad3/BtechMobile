extends TestCase
## Read-only paper doll uses actual armor facings and shared internal structure.


func _unit(quad: bool = false) -> Unit:
	var d := make_def(5)
	d.quad = quad
	d.armor.fill(20)
	d.rear_armor.fill(0)
	for loc: int in Location.HAS_REAR:
		d.rear_armor[loc] = 8
	return Unit.new(1, d, 0, Vector2i.ZERO, 0)


func test_health_levels() -> void:
	var u := _unit()
	var loc := Location.LA
	check_eq(MechDamageDoll.values(u, loc)["health"], MechDamageDoll.Health.INTACT)
	u.armor[loc] = 19
	check_eq(MechDamageDoll.values(u, loc)["health"], MechDamageDoll.Health.WORN)
	u.armor[loc] = 10
	check_eq(MechDamageDoll.values(u, loc)["health"], MechDamageDoll.Health.LOW)
	u.armor[loc] = 0
	check_eq(MechDamageDoll.values(u, loc)["health"], MechDamageDoll.Health.BREACHED)
	u.structure[loc] = 0
	check_eq(MechDamageDoll.values(u, loc)["health"], MechDamageDoll.Health.DESTROYED)


func test_rear_armor_and_shared_structure() -> void:
	var u := _unit()
	var loc := Location.CT
	u.rear_armor[loc] = 1
	check_eq(MechDamageDoll.values(u, loc)["health"], MechDamageDoll.Health.INTACT)
	var rear := MechDamageDoll.values(u, loc, true)
	check_eq(rear["armor"], 1)
	check_eq(rear["max_armor"], 8)
	check_eq(rear["health"], MechDamageDoll.Health.LOW)
	u.structure[loc] -= 1
	check_eq(MechDamageDoll.values(u, loc)["health"], MechDamageDoll.Health.BREACHED)
	check_eq(MechDamageDoll.values(u, loc, true)["health"], MechDamageDoll.Health.BREACHED)
	u.flooded[loc] = true
	check_eq(MechDamageDoll.values(u, loc, true)["health"], MechDamageDoll.Health.FLOODED)


func test_quad_layout_and_partial_damage() -> void:
	var u := _unit(true)
	for quad in [true, false]:
		var parts := MechDamageDoll.layout(quad)
		check_eq(parts.size(), Location.COUNT)
		for loc in Location.COUNT:
			check(parts.has(loc))
			for other in Location.COUNT:
				if other != loc:
					check(not (parts[loc] as Rect2).intersects(parts[other]), "Distinct location silhouettes")
	check_eq(Location.code_for(u.def, Location.LA), "FLL")
	u.armor_partial[Location.LA] = 1
	check_eq(MechDamageDoll.values(u, Location.LA)["health"], MechDamageDoll.Health.WORN)
	u.structure_partial[Location.LA] = 1
	check_eq(MechDamageDoll.values(u, Location.LA)["health"], MechDamageDoll.Health.BREACHED)


func test_record_sheet_contains_doll_without_power_controls() -> void:
	var u := _unit()
	var sheet := RecordSheetView.build(u)
	var doll := sheet.find_child("MechDamageDoll", true, false) as MechDamageDoll
	check(doll != null)
	if doll != null:
		check_eq(doll.unit, u)
	sheet.free()
