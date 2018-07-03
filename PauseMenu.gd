extends Panel

## Signals

signal sounds_toggled(muted)
signal music_toggled(muted)
signal resumed()
signal restarted()

## Constants

const BLUR_MIN = 1.0
const BLUR_MAX = 3.4

## Variables

onready var resume_button = $Resume
onready var restart_button = $Resume/Restart

onready var confirmation_title = $ConfirmationTitle
onready var confirmation_subtitle = $ConfirmationTitle/Subtitle
onready var confirmation_ok_button = $ConfirmationTitle/OK
onready var confirmation_cancel_button = $ConfirmationTitle/Cancel

onready var sounds_checkbox = $MuteSounds
onready var music_checkbox = $MuteMusic
onready var player = $AnimationPlayer

var sounds_mute_enabled = false setget set_sounds_mute, is_sounds_mute
func is_sounds_mute():
	return sounds_mute_enabled
func set_sounds_mute(enabled):
	sounds_mute_enabled = enabled
	if sounds_checkbox: sounds_checkbox.pressed = enabled

var music_mute_enabled = false setget set_music_mute, is_music_mute
func is_music_mute():
	return music_mute_enabled
func set_music_mute(enabled):
	music_mute_enabled = enabled
	if music_checkbox: music_checkbox.pressed = enabled

func _ready():
	VisualServer.canvas_item_set_z_index(self.get_canvas_item(), 99)

	#_test() # DEBUG
	pause_mode = Node.PAUSE_MODE_PROCESS
	set_anchors_preset(PRESET_WIDE)

	resume_button.text = tr("pause.resume")
	resume_button.connect("pressed", self, "_on_resume")
	restart_button.text = tr("pause.restart")
	restart_button.connect("pressed", self, "_on_restart")

	confirmation_title.text = tr("pause.confirmation.title")
	confirmation_title.modulate.a = 0
	confirmation_subtitle.text = tr("pause.confirmation.subtitle")
	confirmation_ok_button.text = tr("pause.confirmation.restart")
	confirmation_ok_button.connect("pressed", self, "_on_restart_confirmed")
	confirmation_cancel_button.text = tr("cancel")
	confirmation_cancel_button.connect("pressed", self, "_on_restart_cancelled")

	assert(sounds_checkbox)
	sounds_checkbox.connect("toggled", self, "_on_sounds_mute")
	sounds_checkbox.pressed = not is_sounds_mute()

	assert(music_checkbox)
	music_checkbox.connect("toggled", self, "_on_music_mute")
	music_checkbox.pressed = not is_music_mute()

	$Tween.interpolate_method(self, "set_blur", BLUR_MIN, BLUR_MAX,
		0.25, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.interpolate_property(self, "modulate", Color(0,0,0,0), Color(1,1,1),
		0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()

	player.play("show-confirmation")
	player.stop(true)
	player.seek(0, true)

func _unhandled_key_input(event):
	if event.scancode == KEY_ESCAPE and event.pressed:
		accept_event()
		_on_resume()

func _on_sounds_mute(checked):
	emit_signal("sounds_toggled", checked)

func _on_music_mute(checked):
	emit_signal("music_toggled", checked)

func set_blur(radius):
	self.material.set_shader_param("blur", radius)

func _on_resume():
	$Tween.interpolate_method(self, "set_blur", BLUR_MAX, BLUR_MIN,
		0.15, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.interpolate_property(self, "modulate", Color(1,1,1), Color(0,0,0,0),
		0.05, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.1)
	$Tween.start()
	yield($Tween, "tween_completed")

	get_tree().paused = false
	emit_signal("resumed")

func _on_restart():
	player.play("show-confirmation")

func _on_restart_confirmed():
	_on_resume()
	emit_signal("restarted")

func _on_restart_cancelled():
	player.play_backwards("show-confirmation")

func _test():
	set_sounds_mute(true); assert(is_sounds_mute())
	set_sounds_mute(false); assert(not is_sounds_mute())
	set_music_mute(true); assert(is_music_mute())
	set_music_mute(false); assert(not is_music_mute())