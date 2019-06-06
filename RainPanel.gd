extends Panel

### Imports

const SoundPlayer = preload("res://SoundPlayer.gd")

### Signals

signal thunderstruck()

### Variables

onready var animation_player := $AnimationPlayer as AnimationPlayer
var striking_timer := Timer.new()
var propagation_timer := Timer.new()
var audio_player := SoundPlayer.new()

const PROPAGATION_DELAY = 1.5
func _ready():
	assert(animation_player)
	add_child(audio_player)

	striking_timer.connect("timeout", self, "play_striking")
	add_child(striking_timer)

	propagation_timer.wait_time = PROPAGATION_DELAY
	add_child(propagation_timer)

	start_raining()

const RAINING_NAME = "start-raining"
func start_raining():
	animation_player.play(RAINING_NAME)
	audio_player.play(Sound.RAIN)
	play_delayed_striking(STRIKING_MIN_DELAY)

const STRIKING_MIN_DELAY = 5
const STRIKING_MAX_DELAY = 12
func rand_striking_delay():
	return rand_range(STRIKING_MIN_DELAY, STRIKING_MAX_DELAY)

func play_delayed_striking(min_delay: float):
	striking_timer.stop()
	striking_timer.wait_time = min_delay + rand_striking_delay()
	striking_timer.start()

const STRIKING_NAME = "strike"
func play_striking():
	if modulate.a < 1: return
	var animation := animation_player.get_animation(STRIKING_NAME); assert(animation)
	assert(not animation.loop)
	animation_player.queue(STRIKING_NAME)
	play_delayed_striking(animation.length)

	propagation_timer.start()
	yield(propagation_timer, "timeout")
	audio_player.play_sound(Sound.THUNDER)
	emit_signal("thunderstruck")

func stop_raining():
	if modulate.a > 0:
		audio_player.stop_sound(Sound.RAIN)
		animation_player.play_backwards(RAINING_NAME)
