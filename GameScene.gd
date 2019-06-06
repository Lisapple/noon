### Main game scene. It manages level and inter-levels presentations.
extends Node

var _DEBUG_ := Helper.DEBUG_ENABLED

### Imports

const LevelsMap = preload("res://data/LevelsMap.gd")
const QuotePanel = preload("res://QuotePanel.gd")
const QuoteManager = preload("res://QuoteManager.gd")
const GameCamera = preload("res://GameCamera.gd")
const SoundPlayer = preload("res://SoundPlayer.gd")

### Constants
var USE_TEST := _DEBUG_ and false
const INTRO_LEVEL_NAME = "Intro"

### Variables
onready var player := $AnimationPlayer as AnimationPlayer

var mapper := LevelsMap.new()

var current_scene: Node
var current_start_name # String?
var end_scene: Node
var camera := GameCamera.new()
var audio_player := SoundPlayer.new()

func _ready():

	if _DEBUG_:
		preload("res://QuoteManager.gd").get_all_quotes()
		assert(not preload("res://QuoteManager.gd").get_quotes(["Level34", "Level33"]).empty())
		progression.available_orbs = [Orb.BLUE, Orb.GREEN, Orb.PURPLE, Orb.RED]
		progression.current_level = null
		progression.save()

	camera.name = "MainCamera"
	add_child(camera)
	add_child(audio_player)

	assert($LifeIndicator and player)
	$LifeIndicator.visible = false

	start_game()

func start_game():
	var level = progression.current_level if progression.current_level else INTRO_LEVEL_NAME
	present_level(level, progression.start_name)
	print("Restoring progression: level %s, orbs %s" % [level, progression.available_orbs])

### Actions

const TUTORIAL_FADE_IN = 0.2

func show_tutorial(duration):
	assert(duration > 1)

	var panel = preload("res://BlurPanel.gd").new()
	add_child(panel)

	panel.add_child($Tutorial)

	var clear = Color(0,0,0,0)
	$Tutorial.visible = true
	var tween = $Tutorial/Tween; tween.start()
	tween.interpolate_property($Tutorial, "modulate", clear, Color(1,1,1),
		TUTORIAL_FADE_IN, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	yield(tween, "tween_completed")

	tween.interpolate_property($Tutorial, "modulate", Color(1,1,1), clear,
		TUTORIAL_FADE_IN, Tween.TRANS_CUBIC, Tween.EASE_IN, duration)
	yield(tween, "tween_completed")

	Helper.remove_from_parent(panel)

var rain_node
func set_raining(enabled, animated=true):
	if enabled and not rain_node:
		rain_node = preload("res://RainPanel.tscn").instance()
		rain_node.connect("thunderstruck", self, "_on_thunderstruck")
		add_child(rain_node)

	if rain_node:
		if animated:
			rain_node.start_raining() if enabled else rain_node.stop_raining()
		else:
			rain_node.modulate.a = int(enabled)
		rain_node.raise()

func _on_thunderstruck():
	print("Thunderstruck!!") # DEBUG
	camera.shake(3.5, 0.25)

func restart_game():
	progression.delete(true)
	start_game()

var severity: int = Severity.NONE
func _on_player_hurt():
	severity += 1
	if severity > Severity.HIGH:
		_on_level_failed(current_scene); return

	set_critical(severity)
	if severity == Severity.LOW:
		var timer := Timer.new(); add_child(timer)
		timer.wait_time = 2; timer.autostart = true
		yield(timer, "timeout")
		var should_disable = (severity != Severity.HIGH)
		enable_critical_effect(not should_disable)
		Helper.remove_from_parent(timer)

var last_failed_level
var last_nightmare_level
func _on_level_failed(scene):
	set_critical(Severity.NONE)

	var name := _get_basename(scene)
	last_failed_level = name

	var nightmare
	var number = int(Helper.first_match("Level(\\d+)", name))
	if   number <= 9:  nightmare = "1"
	elif number <= 19: nightmare = "2"
	elif number <= 29: nightmare = "3"
	elif number <= 39: nightmare = "4"
	elif number <= 49: nightmare = "5"
	else: # Just finish level
		assert(false) # DEBUG (levels 6x can not be failed)
		_on_level_finished("End", scene); return

	var level = "Nightmare%s" % nightmare
	if last_nightmare_level == level: # Nightmare already shown, end game
		var key = "end.failed%d" % (randi() % 6)
		show_end(tr(key))
	else:
		last_nightmare_level = level
		present_level(level)

func set_critical(severity):
	self.severity = severity
	var enabled = (severity != Severity.NONE)
	enable_critical_effect(enabled)

func enable_critical_effect(enabled):
	#$LifeIndicator.visible = true; $LifeIndicator.raise()
	if enabled:
		player.play("Desaturate"); player.queue("heartbeat-critical")
		audio_player.play_sound(Sound.HEART_BEAT)
	else:
		player.stop(); player.play("Resaturate")
		audio_player.stop_sound(Sound.HEART_BEAT)

func present_previous_level_from(start_name: String):
	var name := _get_basename(current_scene)
	var info = mapper.level_before(name, start_name)
	if info == null:
		print("No more level to load!")
		return
	var prev_name = info.keys()[0]; start_name = info.values()[0]
	present_level(prev_name, start_name)

func present_next_level_from(end_name: String):
	var name := _get_basename(current_scene)
	if name.find("Nightmare") != -1:
		name = last_failed_level; assert(name)

	var info = mapper.level_after(name, end_name)
	if info == null:
		show_end()
		return
	var next_name = info.keys()[0]; var start_name = info.values()[0]
	present_level(next_name, start_name)

func show_end(message=null):
	_remove_current_scene()
	var end := preload("res://End.tscn").instance()
	if message: end.message = message
	end.connect("restart_pressed", self, "restart_game")
	add_child(end)

### Presenting level

var loader: ResourceInteractiveLoader
func present_level(name: String, start_name=null):
	var current_name = _get_basename(current_scene) if current_scene else null
	var shows_tutorial := ([current_name, name] == ["Intro", "Level1"])
	var shows_quotes = (current_scene != null and name != "Intro")# and not USE_TEST

	var path := "res://levels/%s.tscn" % name
	assert(ResourceLoader.exists(path)) # Notice: No level for `name`
	loader = ResourceLoader.load_interactive(path)
	assert(loader)
	poll_delta = 0; poll_error = OK

	current_start_name = start_name
	progression.start_name = start_name
	progression.current_level = name
	progression.save()

	if shows_tutorial:
		show_tutorial(4)
	elif shows_quotes:
		var panel := QuotePanel.new()
		if name.begins_with("Nightmare"): # Presenting nightmare
			var orbs = current_scene.get_all_orbs()
			panel.quotes = QuoteManager.get_failure_quotes(name, orbs)
		else:
			panel.set_transition(current_name, name)
		add_child(panel)

		yield(panel, "finished")
		Helper.remove_from_parent(panel)
	else:
		poll_error = loader.wait()
		assert(poll_error == ERR_FILE_EOF)
		present_ready_scene()

var poll_error := OK
var poll_delta := 0.0
func _physics_process(delta: float):
	poll_delta += delta
	if loader and poll_delta >= 0.4:
		poll_delta = 0;
		if poll_error == ERR_FILE_EOF:
			present_ready_scene();
		else:
			assert(poll_error == OK) # Note: Sub-resources will break if `poll` is called once completely loaded
			poll_error = loader.poll()
			assert([OK, ERR_FILE_EOF].has(poll_error))
			print("Loading next level: %d/%d" % [loader.get_stage(), loader.get_stage_count()])

func present_ready_scene():
	assert(loader and poll_error == ERR_FILE_EOF)
	var scene = loader.get_resource().instance(); loader = null
	call_deferred("_present_scene", scene, current_start_name)

func _remove_current_scene():
	if current_scene:
		camera.get_parent().remove_child(camera)
		Helper.remove_from_parent(current_scene)
		current_scene = null

func _present_scene(scene, start_name=null):
	VisualServer.canvas_item_set_z_index($Transition.get_canvas_item(), 20) # Just above QuotePanel
	$Transition.raise()
	var player = $Transition/AnimationPlayer

	# Dismiss the previous scene (after fade transition)
	if current_scene:
		player.play("Panel-Fade")
		yield(player, "animation_finished")

		_remove_current_scene()

	assert(scene.get_script() != null)
	if USE_TEST:
		var TEST_CLASS_PATH = "res://TestGameGridMap.gd"
		var base_class_path = scene.get_script().get_base_script().resource_path
		# Note: Custom GameGridMap (intro, outro, etc.) already inherit from TestGameGridMap, just enable it
		if base_class_path != TEST_CLASS_PATH:
			scene.set_script(load(TEST_CLASS_PATH))
		scene.enable_tests()
	scene.connect("player_hurt", self, "_on_player_hurt")
	scene.connect("game_restarted", self, "restart_game")
	scene.connect("end_reached", self, "_on_end_reached", [scene])
	scene.connect("finished", self, "_on_level_finished", [scene])
	scene.name = _get_basename(scene)
	scene.camera = camera
	scene.season = Season.for_level(scene.name, progression.available_orbs)
	scene.theme = preload("res://models/ImportedMeshLib.meshlib").duplicate(true)
	if start_name:
		scene.set_start(start_name)

	var is_nightmare = scene.name.begins_with("Nightmare")
	set_raining(is_nightmare, false)

	add_child(scene)
	current_scene = scene

	player.play_backwards("Panel-Fade")

func _get_basename(scene) -> String:
	return scene.filename.get_file().get_basename()

func _on_end_reached(end: String, scene):
	progression.current_level = _get_basename(current_scene) # Do not save if level failed
	set_raining(false)
	set_critical(Severity.NONE)

func _on_level_finished(end: String, scene):
	assert(end != current_start_name)
	if end == "Start":
		present_previous_level_from(end)
	else:
		present_next_level_from(end)
