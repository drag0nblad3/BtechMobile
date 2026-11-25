class_name VxDoodads
extends RefCounted
## Small non-colliding ground decoration; never affects terrain or LOS.

static func fill(cells: Dictionary, kind: String, rng: RandomNumberGenerator) -> void:
	match kind:
		"scrub":
			for i in 5:
				var x := rng.randi_range(-3, 3)
				var z := rng.randi_range(-3, 3)
				VxGrid.box(cells, Vector3i(x, 0, z), Vector3i(x, rng.randi_range(1, 3), z), Color("#8c8450"))
		"crate":
			VxGrid.box(cells, Vector3i(-3, 0, -2), Vector3i(2, 3, 2), Color("#8e8166"))
			for x in [-3, 2]:
				VxGrid.box(cells, Vector3i(x, 0, -2), Vector3i(x, 3, 2), Color("#544f45"))
			VxGrid.box(cells, Vector3i(-2, 3, 0), Vector3i(1, 3, 0), Color("#b4a58a"))
		"bollard":
			VxGrid.box(cells, Vector3i(-1, 0, -1), Vector3i(1, 1, 1), Color("#646568"))
			VxGrid.box(cells, Vector3i(0, 2, 0), Vector3i(0, 4, 0), Color("#c39c45"))
			cells[Vector3i(0, 3, 0)] = Color("#353537")
		"debris":
			VxGrid.box(cells, Vector3i(-3, 0, -1), Vector3i(3, 1, 1), Color("#6c6863"))
			VxGrid.box(cells, Vector3i(-3, 2, -1), Vector3i(-1, 2, 1), Color("#987452"))
			VxGrid.box(cells, Vector3i(2, 2, 0), Vector3i(2, 3, 0), Color("#554c44"))
