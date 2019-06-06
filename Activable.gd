extends Spatial

const Activables = preload("res://models/Activables.dae")

const ANIMATION_SPEED = 1.4 # Activable animations speed factor

const AUTO_ANIMS = {
	"Orb": "Orb-float" }

var type

var player setget ,get_animation_player
func get_animation_player():
	return player

var animated_node setget ,get_animated_node
func get_animated_node():
	return animated_node

func _init(type, color, nightmare=false):
	assert(["Door","Hole","Lift","Orb"].has(type))

	self.type = type
	self.name = "Container-%s" % type
	var nodes = Activables.instance()

	player = nodes.get_node("AnimationPlayer"); assert(player)
	player.playback_speed = ANIMATION_SPEED
	player.playback_default_blend_time = 0.1
	player.get_parent().remove_child(player)

	for anim_name in AUTO_ANIMS.values():
		player.get_animation(anim_name).loop = true

	for anim_name in player.get_animation_list():
		if anim_name.begins_with(type):
			# Fix animation path
			var anim = player.get_animation(anim_name)
			assert(anim.get_track_count() > 0)
			for track in anim.get_track_count():
				anim.track_set_path(track, ".") # AnimationPlayer is `node` child
		else:
			# Remove animations not used by `node`
			player.remove_animation(anim_name)
	assert(player.get_animation_list().size() > 0)
	print(player.get_animation_list())

	animated_node = nodes.get_node(type).get_child(0); assert(animated_node)
	animated_node.add_child(player)
	animated_node.get_parent().remove_child(animated_node); add_child(animated_node)
	autoplay()

	# Adjust node material color
	var mat = SpatialMaterial.new()
	mat.albedo_color = color.darkened(0.1)
	mat.emission_enabled = true
	mat.emission_energy = 0.5 if nightmare else 0.12
	mat.emission = color

	var surface = Helper.get_surface_named(animated_node.mesh, "Default-Color")
	if surface != -1:
		animated_node.set_surface_material(surface, mat)

func autoplay():
	for type in AUTO_ANIMS:
		if type == self.type:
			var anim_name = AUTO_ANIMS[type]
			player.queue(anim_name)

func play_at(index, animated=true):
	var name = player.get_animation_list()[index]
	play(name, 1 if animated else INF)

func reverse_at(index, animated=true):
	var name = player.get_animation_list()[index]
	play(name, -(1 if animated else INF))

func play(name, speed_factor=1.0):
	assert(player.has_animation(name))
	var speed = speed_factor * ANIMATION_SPEED
	var from_end = (speed_factor < 0)
	player.play(name, -1, speed, from_end)