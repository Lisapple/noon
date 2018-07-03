### The scene main controller that manages basic scene presentation.
extends Node

var current_scene # Node?

func present_scene(path):
	call_deferred("_deferred_present_scene", path)
func _deferred_present_scene(path):
	print("Will load %s" % path)

	# Dismiss the previous scene
	if current_scene:
		current_scene.get_parent().remove_child(current_scene)

	# Instanciate and present the new scene
	current_scene = load(path).instance()
	var tree = get_tree()
	tree.get_root().add_child(current_scene)
	tree.set_current_scene(current_scene)