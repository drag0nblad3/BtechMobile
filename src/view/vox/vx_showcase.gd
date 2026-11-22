class_name VxShowcase
extends Node3D
## Claude's voxel test: 'Mechs built from data/voxels/*.json, damaged by the
## real rules (HitTable + Damage on a live Unit) and shown with VxDamage,
## plus every animation hook. Separate from the Voxel Mech Lab.

const MODELS := [
	"res://data/voxels/catapult.json",
	"res://data/voxels/hunchback.json",
	"res://data/voxels/atlas_voxel.json",
	"res://data/voxels/wolverine_voxel.json",
	"res://data/voxels/jenner_voxel.json",
	"res://data/voxels/marauder_shape.json",
	"res://data/voxels/marauder.json",
	"res://data/voxels/timber_wolf_shape.json",
	"res://data/voxels/timber_wolf.json",
	"res://data/voxels/warhammer_shape.json",
	"res://data/voxels/warhammer.json",
	"res://data/voxels/archer_shape.json",
	"res://data/voxels/archer.json",
	"res://data/voxels/shadow_hawk_shape.json",
	"res://data/voxels/shadow_hawk.json",
	"res://data/voxels/awesome_shape.json",
	"res://data/voxels/awesome.json",
	"res://data/voxels/griffin_shape.json",
	"res://data/voxels/griffin.json",
	"res://data/voxels/thunderbolt_shape.json",
	"res://data/voxels/thunderbolt.json",
	"res://data/voxels/locust_shape.json",
	"res://data/voxels/locust.json",
	"res://data/voxels/centurion_shape.json",
	"res://data/voxels/centurion.json",
	"res://data/voxels/battlemaster_shape.json",
	"res://data/voxels/battlemaster.json",
	"res://data/voxels/king_crab_shape.json",
	"res://data/voxels/king_crab.json",
	"res://data/voxels/stalker_shape.json",
	"res://data/voxels/stalker.json",
	"res://data/voxels/rifleman_shape.json",
	"res://data/voxels/rifleman.json",
	"res://data/voxels/phoenix_hawk_shape.json",
	"res://data/voxels/phoenix_hawk.json",
	"res://data/voxels/urbanmech_shape.json",
	"res://data/voxels/urbanmech.json",
	"res://data/voxels/firestarter_shape.json",
	"res://data/voxels/firestarter.json",
	"res://data/voxels/black_knight_shape.json",
	"res://data/voxels/black_knight.json",
	"res://data/voxels/vindicator_shape.json",
	"res://data/voxels/vindicator.json",
	"res://data/voxels/flea_shape.json",
	"res://data/voxels/flea.json",
	"res://data/voxels/spider_shape.json",
	"res://data/voxels/spider.json",
	"res://data/voxels/panther_shape.json",
	"res://data/voxels/panther.json",
	"res://data/voxels/raven_shape.json",
	"res://data/voxels/raven.json",
	"res://data/voxels/crab_shape.json",
	"res://data/voxels/crab.json",
	"res://data/voxels/bushwacker_shape.json",
	"res://data/voxels/bushwacker.json",
	"res://data/voxels/orion_shape.json",
	"res://data/voxels/orion.json",
	"res://data/voxels/longbow_shape.json",
	"res://data/voxels/longbow.json",
	"res://data/voxels/jagermech_shape.json",
	"res://data/voxels/jagermech.json",
	"res://data/voxels/highlander_shape.json",
	"res://data/voxels/highlander.json",
	"res://data/voxels/nova_shape.json",
	"res://data/voxels/nova.json",
	"res://data/voxels/summoner_shape.json",
	"res://data/voxels/summoner.json",
	"res://data/voxels/mad_dog_shape.json",
	"res://data/voxels/mad_dog.json",
	"res://data/voxels/shadow_cat_shape.json",
	"res://data/voxels/shadow_cat.json",
]

var mech: VxMech
var unit: Unit
var dice := Dice.new(4242)
var camera: Camera3D
var info: Label
var target := Vector3.ZERO
var _orbit := 2.55
var _pitch := 0.32
var _dist := 3.6
var _last := "Tap a button. Hits use the real hit table and damage rules."
var _model_index := 0
var _hud: CanvasLayer


func _ready() -> void:
	target = VxStage.build(self)
	camera = Camera3D.new()
	camera.fov = 45.0
	add_child(camera)
	_aim_camera()
	reset()


func reset() -> void:
	if mech:
		mech.queue_free()
	mech = VxMech.from_file(MODELS[_model_index])
	add_child(mech)
	unit = Unit.new(1, UnitDb.load_dir().get_def(mech.model.unit_id), 0, Vector2i.ZERO, 0)
	mech.show_unit(unit)
	_make_hud()


func next_mech() -> void:
	_model_index = (_model_index + 1) % MODELS.size()
	_last = "Tap a button. Hits use the real hit table and damage rules."
	reset()


## Rolls a hit location and applies `amount` through the rules engine.
func hit(amount: int, rear: bool = false) -> void:
	if unit.destroyed:
		_last = "Already destroyed. Press RESET."
		return
	var roll := HitTable.roll(dice, FiringArc.REAR if rear else FiringArc.FRONT)
	var steps := Damage.apply(unit, roll["loc"], amount, rear)
	var parts := PackedStringArray()
	for s in steps:
		parts.append("%s -%d armor -%d structure%s" % [Location.code(s["loc"]), s["armor"],
				s["structure"], " DESTROYED" if s["destroyed"] else ""])
	_last = "2d6 = %d → %s\n%s" % [roll["roll"], Location.name_of(roll["loc"]), ", ".join(parts)]
	var from := mech.global_position + (Vector3(0, 1.2, 4) if rear else Vector3(1.5, 1.2, -4))
	var at := mech.location_point(roll["loc"])
	VxFx.shot(self, from, at, amount < 10)
	VxTrails.chips(self, at, mech.model.colors[0])
	mech.show_unit(unit)
	mech.anim.hit_reaction(roll["loc"], rear, amount)
	var legs := int(unit.is_location_destroyed(Location.LL)) + int(unit.is_location_destroyed(Location.RL))
	if (unit.destroyed or legs > 0) and not mech.anim.fallen:
		mech.anim.fall()


func walk(run: bool) -> void:
	if mech.anim.fallen:
		return
	mech.position = Vector3(0, 0, 1.2)
	mech.anim.walk_distance(2.4, run)


func jump() -> void:
	if not mech.anim.fallen:
		mech.position = Vector3(0, 0, 1.0)
		mech.anim.jump(Vector3(0, 0, -2.0))


func fire(weapon: Dictionary) -> void:
	var locs: Array[int] = []
	for loc: int in weapon["locs"]:
		if not unit.is_location_destroyed(loc):
			locs.append(loc)
	if not locs.is_empty() and not mech.anim.fallen and not unit.destroyed:
		mech.anim.fire(locs, target, weapon["kind"])


func _make_hud() -> void:
	if _hud:
		_hud.queue_free()
	_hud = CanvasLayer.new()
	add_child(_hud)
	var top := VBoxContainer.new()
	top.position = Vector2(16, 12)
	_hud.add_child(top)
	UiKit.label(top, "CLAUDE VOXEL TEST · %s" % mech.model.name, UiKit.SMALL)
	info = UiKit.label(top, "", 16)
	info.custom_minimum_size.x = 760
	var rows := VBoxContainer.new()
	rows.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	rows.offset_top = -150
	rows.offset_left = 12
	rows.offset_right = -12
	_hud.add_child(rows)
	var a := HBoxContainer.new()
	var b := HBoxContainer.new()
	rows.add_child(a)
	rows.add_child(b)
	_button(a, "WALK", walk.bind(false))
	_button(a, "RUN", walk.bind(true))
	_button(a, "JUMP", jump)
	_button(a, "FALL", func(): mech.anim.fall())
	_button(a, "STAND", func(): mech.anim.stand_up(not unit.destroyed))
	if mech.model.can_punch:
		_button(a, "PUNCH", func(): mech.anim.punch(1))
	_button(a, "KICK", func(): mech.anim.kick(0))
	_button(a, "NEXT MECH", next_mech).name = "VxNext"
	for w in mech.model.weapons:
		_button(b, w["label"], fire.bind(w))
	_button(b, "HIT 5", hit.bind(5)).name = "VxHit5"
	_button(b, "HIT 20", hit.bind(20)).name = "VxHit20"
	_button(b, "REAR 10", hit.bind(10, true))
	_button(b, "RESET", reset)
	_button(b, "MENU", func(): get_tree().change_scene_to_file("res://scenes/launcher.tscn"))


func _button(row: HBoxContainer, text: String, action: Callable) -> Button:
	var btn := UiKit.button(row, text, action, Vector2(0, 64))
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return btn


func _process(_delta: float) -> void:
	var sheet := PackedStringArray()
	for loc in Location.COUNT:
		var rear := "+%d" % unit.rear_armor[loc] if Location.HAS_REAR.has(loc) else ""
		sheet.append("%s %d%s/%d" % [Location.code(loc), unit.armor[loc], rear, unit.structure[loc]])
	info.text = "%s\nVoxels %d · triangles %d · FPS %d\n%s" % ["  ".join(sheet), mech.voxel_count(),
			mech.triangle_count(), Engine.get_frames_per_second(), _last]


func _aim_camera() -> void:
	var look := Vector3(0, 0.85, 0)
	camera.position = look + Vector3(sin(_orbit) * cos(_pitch), sin(_pitch), cos(_orbit) * cos(_pitch)) * _dist
	camera.look_at(look)


func _unhandled_input(event: InputEvent) -> void:
	var drag := Vector2.ZERO
	if event is InputEventScreenDrag:
		drag = event.relative
	elif event is InputEventMouseMotion and event.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT):
		drag = event.relative
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = maxf(2.5, _dist - 0.4)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(10.0, _dist + 0.4)
	_orbit -= drag.x * 0.01
	_pitch = clampf(_pitch + drag.y * 0.006, 0.05, 1.3)
	_aim_camera()
