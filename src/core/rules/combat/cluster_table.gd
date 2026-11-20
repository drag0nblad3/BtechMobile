class_name ClusterTable
extends RefCounted
## Missiles that hit, by rack size and 2d6 roll (index 0 = roll of 2).
## TODO(rules): verify the classic cluster hits table.

const TABLE := {
	2: [1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2],
	4: [1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4],
	5: [1, 2, 2, 3, 3, 3, 3, 4, 4, 5, 5],
	6: [2, 2, 3, 3, 4, 4, 4, 5, 5, 6, 6],
	10: [3, 3, 4, 6, 6, 6, 6, 8, 8, 10, 10],
	15: [5, 5, 6, 9, 9, 9, 9, 12, 12, 15, 15],
	20: [6, 6, 9, 12, 12, 12, 12, 16, 16, 20, 20],
}


static func hits(rack: int, roll: int) -> int:
	var row: Array = TABLE.get(rack, [])
	if row.is_empty():
		return rack
	return row[clampi(roll, 2, 12) - 2]


## Average missiles hitting, for advice; `bonus` is added to the roll (Artemis).
static func expected(rack: int, bonus: int = 0) -> float:
	var total := 0.0
	for a in range(1, 7):
		for b in range(1, 7):
			total += hits(rack, a + b + bonus)
	return total / 36.0
