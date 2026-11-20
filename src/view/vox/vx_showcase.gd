class_name VxShowcase
extends Node3D
## Claude's voxel test: a Hunchback built from data/voxels/hunchback.json,
## damaged by the real rules (HitTable + Damage on a live Unit) and shown
## with VxDamage, plus every animation hook. Separate from the Voxel Mech Lab.

const MODEL := "res://data/voxels/hunchback.json"
const UNIT_ID := "hunchback_hbk4g"

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


func _ready() -> void:
	target = VxStage.build(self)
	camera = Camera3D.new()
	camera.fov = 45.0
	add_child(camera)
	_aim_camera()
	reset()
	_make_hud()


func reset() -> void:
	if mech:
		mech.queue_free()
	mech = VxMech.from_file(MODEL)
	add_child(mech)
	unit = Unit.new(1, UnitDb.load_dir().get_def(UNIT_ID), 0, Vector2i.ZERO, 0)
	mech.show_unit(unit)


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
	VxFx.shot(self, from, mech.location_point(roll["loc"]), amount < 10)
	mech.show_unit(unit)
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


func fire(loc: int) -> void:
	if not unit.is_location_destroyed(loc) and not mech.anim.fallen:
		mech.anim.fire(loc, target, loc != Location.RT)


func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := VBoxContainer.new()
	top.position = Vector2(16, 12)
	layer.add_child(top)
	UiKit.label(top, "CLAUDE VOXEL TEST · %s" % mech.model.name, UiKit.SMALL)
	info = UiKit.label(top, "", 16)
	info.custom_minimum_size.x = 760
	var rows := VBoxContainer.new()
	rows.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	rows.offset_top = -150
	rows.offset_left = 12
	rows.offset_right = -12
	layer.add_child(rows)
	var a := HBoxContainer.new()
	var b := HBoxContainer.new()
	rows.add_child(a)
	rows.add_child(b)
	for e in [["WALK", walk.bind(false)], ["RUN", walk.bind(true)], ["JUMP", jump],
			["FALL", func(): mech.anim.fall()], ["STAND", func(): mech.anim.stand_up(not unit.destroyed)],
			["PUNCH", func(): mech.anim.punch(1)], ["KICK", func(): mech.anim.kick(0)]]:
		_button(a, e[0], e[1])
	for e in [["AC/20", fire.bind(Location.RT)], ["LASERS", _lasers], ["HIT 5", hit.bind(5)],
			["HIT 20", hit.bind(20)], ["REAR 10", hit.bind(10, true)], ["RESET", reset],
			["MENU", func(): get_tree().change_scene_to_file("res://scenes/launcher.tscn")]]:
		_button(b, e[0], e[1]).name = "Vx" + String(e[0]).replace("/", "").replace(" ", "")


func _lasers() -> void:
	fire(Location.LA)
	get_tree().create_timer(0.15).timeout.connect(fire.bind(Location.RA))


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
