extends Spatial

### Constants

const COUNT = 4

### Variables

onready var node = $Plane
onready var player = $Plane/AnimationPlayer
var material = create_material()

func create_material():
	var mat = SpatialMaterial.new()
	mat.flags_transparent = true
	mat.albedo_texture = preload("res://textures/activable-portal.png")
	mat.emission_enabled = true
	mat.emission = Color(1,1,1,1)
	return mat

func set_orb(orb, season):
	var color = Orb.color(orb, season); color.v *= 1.1 # Set brightness to 110%
	material.emission = color

func _ready():
	node.get_mesh().surface_set_material(0, material)

	var name = player.get_animation_list()[0]; assert(name)
	player.play_backwards(name); player.speed = 0.85
	var animation = player.get_animation(name); animation.loop = true
	var duration = animation.length
	for i in range(COUNT):
		var a_node = node.duplicate(true); add_child(a_node, true)
		var mesh = a_node.mesh.duplicate(true)
		mesh.surface_set_material(0, material.duplicate(true))
		a_node.mesh = mesh

		var a_player = a_node.get_node("AnimationPlayer")
		var anim = a_player.get_animation(name)
		var delay = (i+1)*duration / float(COUNT)
		a_player.play_backwards(name); a_player.seek(delay, true)
