extends Panel

const WAVE_ANIMATION = "wave"

signal finished()

onready var player = $AnimationPlayer

func _init():
	name = "BounceWavePanel"

func _ready():
	self.material = self.material.duplicate(true) # Make unique

var container = BackBufferCopy.new()
func _enter_tree():
	if not container.is_inside_tree():
		container.name = "BounceWaveBackBufferCopy"
		container.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
		container.rect = get_viewport_rect()
		call_deferred("add_container")

func add_container():
	var parent = get_parent()
	parent.remove_child(self)
	container.add_child(self)
	parent.add_child(container)
	set_anchors_preset(Control.PRESET_WIDE)

func play_wave(center, duration=0.8): # void show_wave(Vector2, float?)
	assert(duration > 1e-3)
	assert(get_size() != Vector2(0,0))
	var position = center / get_size() # Get relative position
	self.get_material().set_shader_param("center", position)
	var default_duration = player.get_animation(WAVE_ANIMATION).length
	player.playback_speed = default_duration / duration
	player.play(WAVE_ANIMATION)

	yield(player, "animation_finished")
	emit_signal("finished")

func queue_remove():
	if player.is_playing():
		yield(player, "animation_finished")

	container.queue_free(); container.get_parent().remove_child(container)
