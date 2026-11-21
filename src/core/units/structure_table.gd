class_name StructureTable
extends RefCounted
## Internal structure points by tonnage (standard structure, biped 'Mech).
## Values: [center torso, side torso, arm, leg]. Head is always 3.

const HEAD := 3
const TABLE := {
	20: [6, 5, 3, 4], 25: [8, 6, 4, 6], 30: [10, 7, 5, 7], 35: [11, 8, 6, 8],
	40: [12, 10, 6, 10], 45: [14, 11, 7, 11], 50: [16, 12, 8, 12],
	55: [18, 13, 9, 13], 60: [20, 14, 10, 14], 65: [21, 15, 10, 15],
	70: [22, 15, 11, 15], 75: [23, 16, 12, 16], 80: [25, 17, 13, 17],
	85: [27, 18, 14, 18], 90: [29, 19, 15, 19], 95: [30, 20, 16, 20],
	100: [31, 21, 17, 21],
}


## `quad`: the front legs (LA/RA) use the leg column.
static func points(tonnage: int, loc: int, quad := false) -> int:
	if loc == Location.HEAD:
		return HEAD
	var row: Array = TABLE.get(tonnage, TABLE[50])
	match loc:
		Location.CT:
			return row[0]
		Location.LT, Location.RT:
			return row[1]
		Location.LA, Location.RA:
			return row[3] if quad else row[2]
	return row[3]


## Most armor a location may carry: twice its structure (head: 9).
static func max_armor(tonnage: int, loc: int, quad := false) -> int:
	return 9 if loc == Location.HEAD else 2 * points(tonnage, loc, quad)
