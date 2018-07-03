extends "res://TestGameGridMap.gd"

func _update_cell(cell, new_item):
	var orientation = get_cell_item_orientationv(cell)
	set_cell_itemv(cell, new_item, orientation)

func start():
	var hole = get_holes()[0]
	var doors = {}; for door in get_doors():
		var orb = get_cell_orb(door)
		doors[orb] = door

	if get_ends().has(get_begin()): # Player returns to this level
		# Open blue/green doors
		for orb in [Orb.BLUE, Orb.GREEN]:
			_update_cell(doors[orb], ITEMS[DOOR][orb])
			set_door_closed(doors[orb], false)
		# Change `hole` orb to red
		_update_cell(hole, ITEMS[HOLE_EMPTY][Orb.RED])

	.start()