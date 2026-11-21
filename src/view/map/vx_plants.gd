class_name VxPlants
extends RefCounted
## Small voxel ground props: grass tufts, flowers, bushes, rocks and rubble
## chunks. Tiny grids at a fine pitch, a few seeded variants each, cached.

const PITCH := 0.03
const VARIANTS := 3
const GRASS := [Color("#6a9a3a"), Color("#7aa844"), Color("#86b04c"), Color("#5a8a32")]
const PETALS := [Color("#e0d050"), Color("#e8e8e0"), Color("#c85a8a"), Color("#d07a30")]
const STONE := [Color("#7a756c"), Color("#6a665e"), Color("#8a8478")]
const CONCRETE := [Color("#8a8680"), Color("#76726c"), Color("#9a6a50")]

static var _cache := {}


## kind: tuft, flower, bush, rock, chunk.
static func mesh(kind: String, variant: int) -> ArrayMesh:
	var key := [kind, variant]
	if not _cache.has(key):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(key)
		var cells := {}
		match kind:
			"tuft": _tuft(cells, rng)
			"flower": _flower(cells, rng)
			"bush": _bush(cells, rng)
			"rock": _rock(cells, rng, STONE)
			_: _rock(cells, rng, CONCRETE, true)
		_cache[key] = VxGrid.mesh(cells, PITCH, Vector3(0.5, 0, 0.5))
	return _cache[key]


static func _tuft(cells: Dictionary, rng: RandomNumberGenerator) -> void:
	for i in 6:
		var at := Vector3i(rng.randi_range(-2, 2), 0, rng.randi_range(-2, 2))
		var c: Color = GRASS[rng.randi() % GRASS.size()]
		VxGrid.box(cells, at, at + Vector3i(0, rng.randi_range(2, 5), 0), c)


static func _flower(cells: Dictionary, rng: RandomNumberGenerator) -> void:
	_tuft(cells, rng)
	var petal: Color = PETALS[rng.randi() % PETALS.size()]
	for i in 2:
		var at := Vector3i(rng.randi_range(-2, 2), 0, rng.randi_range(-2, 2))
		var h := rng.randi_range(4, 6)
		VxGrid.box(cells, at, at + Vector3i(0, h - 1, 0), GRASS[0])
		cells[at + Vector3i(0, h, 0)] = petal


static func _bush(cells: Dictionary, rng: RandomNumberGenerator) -> void:
	var c: Color = GRASS[rng.randi() % GRASS.size()].darkened(0.1)
	var r := rng.randf_range(3.0, 4.0)
	var n := ceili(r)
	for x in range(-n, n + 1):
		for y in range(0, n + 1):
			for z in range(-n, n + 1):
				if Vector3(x, y * 1.4, z).length() <= r:
					cells[Vector3i(x, y, z)] = c if y > 1 else c.darkened(0.2)


static func _rock(cells: Dictionary, rng: RandomNumberGenerator, palette: Array, blocky := false) -> void:
	var c: Color = palette[rng.randi() % palette.size()]
	var lumps := rng.randi_range(1, 3)
	for i in lumps:
		var w := rng.randi_range(2, 4)
		var h := rng.randi_range(1, 3) if not blocky else rng.randi_range(1, 2)
		var at := Vector3i(rng.randi_range(-2, 1), 0, rng.randi_range(-2, 1))
		VxGrid.box(cells, at, at + Vector3i(w - 1, h - 1, rng.randi_range(1, 3)), c.darkened(0.08 * i))
	if blocky and rng.randf() < 0.5:  # bent rebar
		VxGrid.box(cells, Vector3i(0, 1, 0), Vector3i(0, 4, 0), Color("#5a3a2a"))
