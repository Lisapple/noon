tool
extends Skeleton

### Imports

var MultipleAnimationsPlayer = preload("res://MultipleAnimationsPlayer.gd")

### Signals

signal on_should_update_camera()
signal move_finished()

### Constants

const TWEEN_NAME = "default-tween"

### Variables

func get_animation_player():
	return animation_player
var animation_player setget , get_animation_player

onready var node = get_node("Player")
var outline_node
var tween

func shortest(deg):
	var shortest_angle = fmod(deg, 360)
	if shortest_angle > 180: shortest_angle -= 360
	elif shortest_angle < -180: shortest_angle += 360
	assert(abs(shortest_angle) <= 180)
	return shortest_angle

func shortest3(vector):
	return Vector3(shortest(vector.x), shortest(vector.y), shortest(vector.z))

# Note: `set_origin_rotate(1, null, Vector3(0, 90, 0)` would not work with method animation (`angle_deg` will become also null),
#   so use `rotate(duration, angle_deg)` for transform without translation
func set_origin_rotate(duration, translation, angle_deg=null): # void set_origin_rotate(float, Vector3, Vector3?)
	print("Move player (from %s): " % self.translation, translation, angle_deg, " in %ss" % duration)
	if angle_deg != null:
		var rot = node.rotation_degrees
		tween.interpolate_property(node, "transform/rotation", rot, rot+shortest3(angle_deg), duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property(self, "transform/translation", get_translation(), translation, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func rotate(duration, angle_deg): # void set_origin_rotate(float, Vector3?)
	set_origin_rotate(duration, get_translation(), angle_deg)

func update_camera():
	emit_signal("on_should_update_camera")

func on_finished_move():
	emit_signal("move_finished")

func _ready():
	assert(node)

	# TODO: Check that `AnimationPlayer` is linked to 'res://models/PlayerAnimationPlayer.tscn'

	animation_player = MultipleAnimationsPlayer.new()
	animation_player.name = "animation-player"
	add_child(animation_player)

	tween = Tween.new(); tween.name = TWEEN_NAME
	add_child(tween)

	#if node.get_mesh().has_method("create_outline"): # Godot 2.1.4+
	#	set_process(true)

	#	outline_node = node.duplicate()
	#	outline_node.set_rotation(Vector3(0,0,0))
	#	outline_node.set_translation(Vector3(0,0,0))
	#	outline_node.set_scale(Vector3(1,1,1))
	#	var mesh = outline_node.get_mesh()
	#	outline_node.set_mesh(mesh.create_outline(0.028))
	#	#add_child(outline_node)

	#	var material = FixedMaterial.new()
	#	material.set_parameter(FixedMaterial.PARAM_DIFFUSE, Color(1,1,1))
	#	material.set_parameter(FixedMaterial.PARAM_SPECULAR, Color(0,0,0))
	#	material.set_parameter(FixedMaterial.PARAM_EMISSION, Color(0.7,0.5,0.5))
	#	outline_node.set_material_override(material)

#func _process(delta):
#	outline_node.set_rotation(node.get_rotation())
