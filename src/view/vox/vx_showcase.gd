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
	"res://data/voxels/annihilator_shape.json",
	"res://data/voxels/annihilator.json",
	"res://data/voxels/nightstar_shape.json",
	"res://data/voxels/nightstar.json",
	"res://data/voxels/dire_wolf_shape.json",
	"res://data/voxels/dire_wolf.json",
	"res://data/voxels/warhawk_shape.json",
	"res://data/voxels/warhawk.json",
	"res://data/voxels/grasshopper_shape.json",
	"res://data/voxels/grasshopper.json",
	"res://data/voxels/quickdraw_shape.json",
	"res://data/voxels/quickdraw.json",
	"res://data/voxels/dragon_shape.json",
	"res://data/voxels/dragon.json",
	"res://data/voxels/trebuchet_shape.json",
	"res://data/voxels/trebuchet.json",
	"res://data/voxels/cicada_shape.json",
	"res://data/voxels/cicada.json",
	"res://data/voxels/commando_shape.json",
	"res://data/voxels/commando.json",
	"res://data/voxels/javelin_shape.json",
	"res://data/voxels/javelin.json",
	"res://data/voxels/fire_moth_shape.json",
	"res://data/voxels/fire_moth.json",
	"res://data/voxels/mist_lynx_shape.json",
	"res://data/voxels/mist_lynx.json",
	"res://data/voxels/banshee_shape.json",
	"res://data/voxels/banshee.json",
	"res://data/voxels/cyclops_shape.json",
	"res://data/voxels/cyclops.json",
	"res://data/voxels/mauler_shape.json",
	"res://data/voxels/mauler.json",
	"res://data/voxels/enforcer_shape.json",
	"res://data/voxels/enforcer.json",
	"res://data/voxels/blackjack_shape.json",
	"res://data/voxels/blackjack.json",
	"res://data/voxels/crusader_shape.json",
	"res://data/voxels/crusader.json",
	"res://data/voxels/cataphract_shape.json",
	"res://data/voxels/cataphract.json",
	"res://data/voxels/ostsol_shape.json",
	"res://data/voxels/ostsol.json",
	"res://data/voxels/ostroc_shape.json",
	"res://data/voxels/ostroc.json",
	"res://data/voxels/gargoyle_shape.json",
	"res://data/voxels/gargoyle.json",
	"res://data/voxels/stormcrow_shape.json",
	"res://data/voxels/stormcrow.json",
	"res://data/voxels/wasp_shape.json",
	"res://data/voxels/wasp.json",
	"res://data/voxels/stinger_shape.json",
	"res://data/voxels/stinger.json",
	"res://data/voxels/mercury_shape.json",
	"res://data/voxels/mercury.json",
	"res://data/voxels/mongoose_shape.json",
	"res://data/voxels/mongoose.json",
	"res://data/voxels/valkyrie_shape.json",
	"res://data/voxels/valkyrie.json",
	"res://data/voxels/wolfhound_shape.json",
	"res://data/voxels/wolfhound.json",
	"res://data/voxels/assassin_shape.json",
	"res://data/voxels/assassin.json",
	"res://data/voxels/vulcan_shape.json",
	"res://data/voxels/vulcan.json",
	"res://data/voxels/hatchetman_shape.json",
	"res://data/voxels/hatchetman.json",
	"res://data/voxels/kintaro_shape.json",
	"res://data/voxels/kintaro.json",
	"res://data/voxels/dervish_shape.json",
	"res://data/voxels/dervish.json",
	"res://data/voxels/whitworth_shape.json",
	"res://data/voxels/whitworth.json",
	"res://data/voxels/hollander_shape.json",
	"res://data/voxels/hollander.json",
	"res://data/voxels/flashman_shape.json",
	"res://data/voxels/flashman.json",
	"res://data/voxels/victor_shape.json",
	"res://data/voxels/victor.json",
	"res://data/voxels/zeus_shape.json",
	"res://data/voxels/zeus.json",
	"res://data/voxels/thug_shape.json",
	"res://data/voxels/thug.json",
	"res://data/voxels/charger_shape.json",
	"res://data/voxels/charger.json",
	"res://data/voxels/kodiak_shape.json",
	"res://data/voxels/kodiak.json",
	"res://data/voxels/executioner_shape.json",
	"res://data/voxels/executioner.json",
	"res://data/voxels/hellbringer_shape.json",
	"res://data/voxels/hellbringer.json",
	"res://data/voxels/turkina_shape.json",
	"res://data/voxels/turkina.json",
	"res://data/voxels/kit_fox_shape.json",
	"res://data/voxels/kit_fox.json",
	"res://data/voxels/ice_ferret_shape.json",
	"res://data/voxels/ice_ferret.json",
	"res://data/voxels/adder_shape.json",
	"res://data/voxels/adder.json",
	"res://data/voxels/akuma_shape.json",
	"res://data/voxels/akuma.json",
	"res://data/voxels/albatross_shape.json",
	"res://data/voxels/albatross.json",
	"res://data/voxels/argus_shape.json",
	"res://data/voxels/argus.json",
	"res://data/voxels/axman_shape.json",
	"res://data/voxels/axman.json",
	"res://data/voxels/caesar_shape.json",
	"res://data/voxels/caesar.json",
	"res://data/voxels/chimera_shape.json",
	"res://data/voxels/chimera.json",
	"res://data/voxels/clint_shape.json",
	"res://data/voxels/clint.json",
	"res://data/voxels/crossbow_shape.json",
	"res://data/voxels/crossbow.json",
	"res://data/voxels/devastator_shape.json",
	"res://data/voxels/devastator.json",
	"res://data/voxels/emperor_shape.json",
	"res://data/voxels/emperor.json",
	"res://data/voxels/excalibur_shape.json",
	"res://data/voxels/excalibur.json",
	"res://data/voxels/exterminator_shape.json",
	"res://data/voxels/exterminator.json",
	"res://data/voxels/falconer_shape.json",
	"res://data/voxels/falconer.json",
	"res://data/voxels/firebee_shape.json",
	"res://data/voxels/firebee.json",
	"res://data/voxels/firefly_shape.json",
	"res://data/voxels/firefly.json",
	"res://data/voxels/goliath_shape.json",
	"res://data/voxels/goliath.json",
	"res://data/voxels/grendel_shape.json",
	"res://data/voxels/grendel.json",
	"res://data/voxels/grizzly_shape.json",
	"res://data/voxels/grizzly.json",
	"res://data/voxels/guillotine_shape.json",
	"res://data/voxels/guillotine.json",
	"res://data/voxels/hatamoto_chi_shape.json",
	"res://data/voxels/hatamoto_chi.json",
	"res://data/voxels/hellspawn_shape.json",
	"res://data/voxels/hellspawn.json",
	"res://data/voxels/hermes_ii_shape.json",
	"res://data/voxels/hermes_ii.json",
	"res://data/voxels/hoplite_shape.json",
	"res://data/voxels/hoplite.json",
	"res://data/voxels/linebacker_shape.json",
	"res://data/voxels/linebacker.json",
	"res://data/voxels/mackie_shape.json",
	"res://data/voxels/mackie.json",
	"res://data/voxels/night_gyr_shape.json",
	"res://data/voxels/night_gyr.json",
	"res://data/voxels/pack_hunter_shape.json",
	"res://data/voxels/pack_hunter.json",
	"res://data/voxels/piranha_shape.json",
	"res://data/voxels/piranha.json",
	"res://data/voxels/scorpion_shape.json",
	"res://data/voxels/scorpion.json",
	"res://data/voxels/supernova_shape.json",
	"res://data/voxels/supernova.json",
	"res://data/voxels/tarantula_shape.json",
	"res://data/voxels/tarantula.json",
	"res://data/voxels/thanatos_shape.json",
	"res://data/voxels/thanatos.json",
	"res://data/voxels/viper_shape.json",
	"res://data/voxels/viper.json",
	"res://data/voxels/battleaxe_shape.json",
	"res://data/voxels/battleaxe.json",
	"res://data/voxels/chameleon_shape.json",
	"res://data/voxels/chameleon.json",
	"res://data/voxels/crockett_shape.json",
	"res://data/voxels/crockett.json",
	"res://data/voxels/gunslinger_shape.json",
	"res://data/voxels/gunslinger.json",
	"res://data/voxels/havoc_shape.json",
	"res://data/voxels/havoc.json",
	"res://data/voxels/hel_shape.json",
	"res://data/voxels/hel.json",
	"res://data/voxels/helios_shape.json",
	"res://data/voxels/helios.json",
	"res://data/voxels/howler_shape.json",
	"res://data/voxels/howler.json",
	"res://data/voxels/hunchback_iic_shape.json",
	"res://data/voxels/hunchback_iic.json",
	"res://data/voxels/icarus_ii_shape.json",
	"res://data/voxels/icarus_ii.json",
	"res://data/voxels/katana_shape.json",
	"res://data/voxels/katana.json",
	"res://data/voxels/lancelot_shape.json",
	"res://data/voxels/lancelot.json",
	"res://data/voxels/legionnaire_shape.json",
	"res://data/voxels/legionnaire.json",
	"res://data/voxels/malice_shape.json",
	"res://data/voxels/malice.json",
	"res://data/voxels/merlin_shape.json",
	"res://data/voxels/merlin.json",
	"res://data/voxels/nightsky_shape.json",
	"res://data/voxels/nightsky.json",
	"res://data/voxels/ostscout_shape.json",
	"res://data/voxels/ostscout.json",
	"res://data/voxels/ostwar_shape.json",
	"res://data/voxels/ostwar.json",
	"res://data/voxels/penetrator_shape.json",
	"res://data/voxels/penetrator.json",
	"res://data/voxels/pillager_shape.json",
	"res://data/voxels/pillager.json",
	"res://data/voxels/sagittaire_shape.json",
	"res://data/voxels/sagittaire.json",
	"res://data/voxels/scarabus_shape.json",
	"res://data/voxels/scarabus.json",
	"res://data/voxels/sentinel_shape.json",
	"res://data/voxels/sentinel.json",
	"res://data/voxels/shockwave_shape.json",
	"res://data/voxels/shockwave.json",
	"res://data/voxels/shogun_shape.json",
	"res://data/voxels/shogun.json",
	"res://data/voxels/spartan_shape.json",
	"res://data/voxels/spartan.json",
	"res://data/voxels/spector_shape.json",
	"res://data/voxels/spector.json",
	"res://data/voxels/starslayer_shape.json",
	"res://data/voxels/starslayer.json",
	"res://data/voxels/suburbanmech_shape.json",
	"res://data/voxels/suburbanmech.json",
	"res://data/voxels/thunder_hawk_shape.json",
	"res://data/voxels/thunder_hawk.json",
	"res://data/voxels/thunder_stallion_shape.json",
	"res://data/voxels/thunder_stallion.json",
	"res://data/voxels/venom_shape.json",
	"res://data/voxels/venom.json",
	"res://data/voxels/ymir_shape.json",
	"res://data/voxels/ymir.json",
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


## Android Back remains available with automatic back-to-exit disabled.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().change_scene_to_file("res://scenes/launcher.tscn")


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
			return
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://scenes/launcher.tscn")


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


func prev_mech() -> void:
	_model_index = posmod(_model_index - 1, MODELS.size())
	_last = "Tap a button. Hits use the real hit table and damage rules."
	reset()


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
	UiKit.label(top, "CLAUDE VOXEL TEST · %s (%d/%d)" % [mech.model.name, _model_index + 1, MODELS.size()], UiKit.SMALL)
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
	_button(a, "PREV MECH", prev_mech)
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
