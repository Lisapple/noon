extends "res://TestGameGridMap.gd"

var allows_reload_spots = false

func start():
	.start()

	# Sit player until stand up animation
	var name = Player.name(Anim.STAND_UP)
	player.get_animation_player().play(name)
	player.get_animation_player().stop(false)
	player.get_animation_player().seek(0, true)

	stand_up()

func init_path_extension():
	.init_path_extension(false, true)

func stand_up():
	queue_animation(Anim.STAND_UP, false, 2.0)
	yield(self, "_anim_finished")

	allows_reload_spots = true
	reload_spots()

func reload_spots():
	if allows_reload_spots: # Do not show spots until player stood up
		.reload_spots()

func get_spots():
	var spots = .get_spots()
	spots.erase(get_start())
	return spots