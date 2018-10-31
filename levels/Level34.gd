extends "res://TestGameGridMap.gd"

var start_end # Vector3

func _test_level_integrity():
	pass

func start():
	if Helper.DEBUG_ENABLED:
		progression.available_orbs.erase(Orb.RED)

	start_end = get_cells(START)[0]
	assert(get_orbs().size() == 1)
	.start()

func _orb_picked():
	return progression.available_orbs.has(Orb.RED)

func get_start():
	return get_orbs()[0] if _orb_picked() else start_end
func get_ends():
	return [start_end] if _orb_picked() else []
