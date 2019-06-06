extends GridMap

var _DEBUG_ = Helper.DEBUG_ENABLED

signal shortest_path_found(path)

const UP = Vector3(0, 1, 0)
const AREA_OFFSET = Vector3(0.5, 0.5, 0.5)

const PATH_PREFIX = "Path"
const STAIRS_PREFIX = "Stairs"
var START; const START_NAME = "Start"
var END; const END_NAME = "End"
var END_2; const END_2_NAME = "End-2"
var PATH_EXT; const PATH_EXT_NAME = "Path-Extension" # For level extensions path

enum Type { DOOR, HOLE, LIFT, TORCH, ORB }
enum Type_ {
	DOOR_CLOSED = 10, HOLE_EMPTY, LIFT_UP, TORCH_ON }
var SUFFIXES = {
	Type.DOOR: "Door", Type_.DOOR_CLOSED: "Door-Closed",
	Type.HOLE: "Hole", Type_.HOLE_EMPTY: "Hole-Empty",
	Type.LIFT: "Lift", Type_.LIFT_UP: "Lift-Up",
	Type.TORCH: "Torch", Type_.TORCH_ON: "Torch-On",
	Type.ORB: "Orb"
}
const UNSUPPORTED_NAMES = [
	"Y-Door", "Y-Door-Closed", "Y-Hole", "Y-Hole-Empty", "Y-Lift", "Y-Lift-Up",
	"N-Orb"
]

var ITEMS = {
	Type.DOOR: { }, Type_.DOOR_CLOSED: { },
	Type.HOLE: { }, Type_.HOLE_EMPTY: { },
	Type.LIFT: { }, Type_.LIFT_UP: { },
	Type.TORCH: { }, Type_.TORCH_ON: { },
	Type.ORB: { }
}

var WALKABLES = []

func get_all_orbs() -> Array:
	var orbs = []; for cell in get_used_cells():
		orbs.append(get_cell_orb(cell))
	Helper.distinct(orbs); orbs.erase(-1)
	return orbs

func _item_type(item) -> int: # -1 for invalid
	for type in ITEMS:
		if ITEMS[type].values().has(item): return type
	return -1

func _item_orb(item) -> int: # -1 for no orb
	for type in ITEMS:
		for orb in ITEMS[type]:
			if ITEMS[type][orb] == item: return orb
	return -1

class Actor: # Target to define path propagation constraints
	enum {
		PLAYER, # Can only move on same level (lift needed otherwise)
		PARTICLE, # Can move to lower levels
		_HOLLOW = 99 # Can follow any path for any level (Note: used for wolf)
	}

class Behaviour: # Behaviour enum for particles
	enum {
		PASSING, # Passing through cell (without activating)
		BOUNCING, # Bouncing back against non-matching activable
		ABSORBED, # Absorbed by intermediate activable
		REACHED # Absorbed at the particle path end (activable or boy)
	}

func _ready():
	init_constants()
	init_activable_states()

func init_constants():
	START = mesh_library.find_item_by_name(START_NAME)
	END = mesh_library.find_item_by_name(END_NAME)
	END_2 = mesh_library.find_item_by_name(END_2_NAME)
	WALKABLES = [START, END, END_2]

	for item in theme.get_item_list():
		for prefix in [PATH_PREFIX, STAIRS_PREFIX]:
			if theme.get_item_name(item).begins_with(prefix):
				WALKABLES.append(item)
	assert(not WALKABLES.has(-1))

	PATH_EXT = mesh_library.find_item_by_name(PATH_EXT_NAME)
	WALKABLES.erase(PATH_EXT)

	for orb in Orb.ALL:
		var prefix = Orb.prefix(orb)
		for suffix in SUFFIXES:
			var name := "%s-%s" % [prefix, SUFFIXES[suffix]]
			if not UNSUPPORTED_NAMES.has(name):
				var item := mesh_library.find_item_by_name(name); assert(item != -1)
				ITEMS[suffix][orb] = item

func init_activable_states():
	for cell in get_used_cells():
		var item = get_cell_itemv(cell)
		var orb = _item_orb(item)
		var orientation = get_cell_item_orientationv(cell)
		var type = _item_type(item)
		match type:
			Type.DOOR, Type_.DOOR_CLOSED:
				set_door_closed(cell, type == Type_.DOOR_CLOSED)
				set_cell_itemv(cell, ITEMS[Type.DOOR][orb], orientation)
			Type.HOLE, Type_.HOLE_EMPTY:
				set_hole_empty(cell, type == Type_.HOLE_EMPTY)
				set_cell_itemv(cell, ITEMS[Type_.HOLE_EMPTY][orb], orientation)
			Type.TORCH, Type_.TORCH_ON:
				set_torch_light(cell, type == Type_.TORCH_ON)
				set_cell_itemv(cell, ITEMS[Type.TORCH][orb], orientation)
			Type.LIFT, Type_.LIFT_UP:
				set_lift_up(cell, type == Type_.LIFT_UP)
				set_cell_itemv(cell, ITEMS[Type.LIFT][orb], orientation)
			Type.ORB:
				set_orb_picked(cell, false)

var areas := {} # {Vector3 : Area}
func enable_hotspot(cell: Vector3, enabled:=true):
	if enabled and not areas.has(cell):
		var area := Area.new()
		area.translation = cell + AREA_OFFSET + Vector3(0, int(is_lift_up(cell)), 0)
		area.input_ray_pickable = true
		add_child(area)
		areas[cell] = area

		var shape := CollisionShape.new()
		shape.shape = BoxShape.new()
		shape.shape.extents = Vector3(0.5,0.5,0.5)
		area.add_child(shape)

	elif not enabled and areas.has(cell):
		remove_child(areas[cell])
		areas.erase(cell)

func get_start() -> Vector3:
	var starts := get_cells(START); assert(starts.size() == 1)
	return starts[0]

# Returns an array with end cell, then second end cell if present.
func get_ends() -> PoolVector3Array:
	var ends := get_cells(END) + get_cells(END_2); assert([1,2].has(ends.size()))
	return ends

# Returns true if `p1` and `p2` lie on the same Y axis.
func _is_same_plane(p1: Vector3, p2: Vector3) -> bool:
	return (p1.x == p2.x and p1.z == p2.z)

func _exists(cell: Vector3) -> bool: # `cell` has been set on grid map.
	return (get_cell_itemv(cell) != GridMap.INVALID_CELL_ITEM)

func is_valid(cell: Vector3) -> bool: # `cell` exists or is a lift up
	#if is_lift_up(get_lift_bottom(cell)): return true
	return _exists(cell)

func is_stairs(cell: Vector3) -> bool:
	var item := get_cell_itemv(cell)
	if item != GridMap.INVALID_CELL_ITEM:
		return theme.get_item_name(item).begins_with(STAIRS_PREFIX)
	return false

func get_cell_orb(cell: Vector3) -> int: # Get the orb associated to `cell`, or -1 if none or invalid
	var item := get_cell_itemv(cell)
	return _item_orb(item)

func get_cell_type(cell: Vector3) -> int:
	return _item_type(get_cell_itemv(cell))

func get_lifts() -> PoolVector3Array:
	return get_cells_for(Type.LIFT)
func get_lift_bottom(cell: Vector3) -> Vector3:
	var bottom = cell - Vector3(0,1,0)
	if lifts_up.has(bottom) and lifts_up[bottom]:
		return bottom
	return cell
func is_lift_bottom(cell: Vector3) -> bool:
	return [Type.LIFT, Type_.LIFT_UP].has(get_cell_type(cell))
func is_lift(cell: Vector3) -> bool:
	cell = get_lift_bottom(cell)
	return is_lift_bottom(cell)
var lifts_up = {}
func is_lift_up(cell: Vector3) -> bool:
	cell = get_lift_bottom(cell)
	return lifts_up.has(cell) and lifts_up[cell]
func set_lift_up(cell: Vector3, up: bool):
	cell = get_lift_bottom(cell)
	lifts_up[cell] = up

func get_doors() -> PoolVector3Array:
	return get_cells_for(Type.DOOR) + get_cells_for(Type_.DOOR_CLOSED)
func is_door(cell: Vector3) -> bool:
	return [Type.DOOR, Type_.DOOR_CLOSED].has(get_cell_type(cell))
var doors_closed := {}
func is_door_closed(cell: Vector3) -> bool:
	return doors_closed[cell] if doors_closed.has(cell) else false
func set_door_closed(cell: Vector3, closed: bool):
	doors_closed[cell] = closed

func get_holes() -> PoolVector3Array:
	return get_cells_for(Type.HOLE)+get_cells_for(Type_.HOLE_EMPTY)
func is_hole(cell: Vector3) -> bool:
	return [Type.HOLE, Type_.HOLE_EMPTY].has(get_cell_type(cell))
var holes_empty = {}
func is_hole_empty(cell: Vector3) -> bool:
	return holes_empty[cell] if holes_empty.has(cell) else false
func set_hole_empty(cell: Vector3, empty: bool):
	holes_empty[cell] = empty

func get_torches() -> PoolVector3Array:
	return get_cells_for(Type.TORCH)+get_cells_for(Type_.TORCH_ON)
func is_torch(cell: Vector3) -> bool:
	return [Type.TORCH, Type_.TORCH_ON].has(get_cell_type(cell))
var torchs_on = {}
func is_torch_light(cell: Vector3) -> bool:
	return torchs_on[cell] if torchs_on.has(cell) else false
func set_torch_light(cell: Vector3, on: bool):
	torchs_on[cell] = on

func get_orbs() -> PoolVector3Array:
	return get_cells_for(Type.ORB)
func is_orb(cell: Vector3) -> bool:
	return get_cell_type(cell) == Type.ORB
var orb_picked := {}
func is_orb_picked(cell: Vector3) -> bool:
	return orb_picked[cell] if orb_picked.has(cell) else false
func set_orb_picked(cell: Vector3, picked: bool):
	orb_picked[cell] = picked

### Player's path

var walkables := {}
# Returns true if any actor can walk on `cell`
# TODO: Rename this method (here, 'walkable' doesn't mean that player can walk on)
func is_walkable(cell: Vector3) -> bool:
	var item = get_cell_itemv(cell)
	if not walkables.has(item): walkables[item] = _is_walkable(cell) # Cache value
	return walkables[item]
func _is_walkable(cell: Vector3) -> bool:
	if is_door(cell) or is_hole(cell) or is_lift(cell) or is_torch(cell) or is_orb(cell): # ???: TORCH walkable?
		return true
	return WALKABLES.has(get_cell_itemv(cell))

func is_matching(cell: Vector3, orb) -> bool:
	return (get_cell_orb(cell) == orb)

# Returns if `orb` can be absorbed by `cell`. Only check if `cell` can be absorbed if `orb` is nil
func can_absorb(cell: Vector3, orb: int) -> bool: # TODO: `bool Cell.can_absorb(orb)` with `Cell extends Vector3`
	if orb and not is_matching(cell, orb): return false
	return (is_door(cell) and is_door_closed(cell) or
			is_hole(cell) and not is_hole_empty(cell) or
			is_lift(cell) and is_lift_up(cell) or
			is_torch(cell) and is_torch_light(cell))

# Returns if `orb` can activate `cell`. Only check if `cell` can be activated if `orb` is nil
func can_activate(cell: Vector3, orb: int) -> bool:
	if orb and not is_matching(cell, orb): return false
	return (is_door(cell) and not is_door_closed(cell) or
			is_hole(cell) and is_hole_empty(cell) or
			is_lift(cell) and not is_lift_up(cell) or
			is_torch(cell) and not is_torch_light(cell))

# Returns if the cell obstructs player moving.
func obstructs(cell: Vector3, actor):
	if actor == Actor._HOLLOW: return false

	if is_door(cell):
		return is_door_closed(cell)
	elif is_hole(cell):
		return is_hole_empty(cell)
	elif is_torch(cell):
		return (actor == Actor.PLAYER)
	elif is_orb(cell):
		return not is_orb_picked(cell)

	return false # Lifts and walkables

# Returns positions with a common face on X and Z axes.
const NEIGHBORS = [
	Vector3( 0, 0,-1), Vector3( 0, 0, 1), Vector3(-1, 0, 0), Vector3( 1, 0, 0) ]

func _neighbors(cell: Vector3) -> PoolVector3Array:
	return PoolVector3Array([
		cell + Vector3( 0, 0,-1),
		cell + Vector3( 0, 0, 1),
		cell + Vector3(-1, 0, 0),
		cell + Vector3( 1, 0, 0) ])

# Returns all walkable cells with one or more edges in common.
func edges(cell: Vector3) -> PoolVector3Array:
	# TODO: Need caching?
	var positions := PoolVector3Array()
	for dy in [-1, 0, 1]:
		var at := cell + Vector3(0, dy, 0)
		for offset in NEIGHBORS:
			#var is_up_lift = is_lift_up(get_lift_bottom(neighboor))
			if is_walkable(at+offset):
				positions.append(at+offset)
	return positions

func allow_reaching(actor, from, to, orb=null):
	assert(actor != Actor.PARTICLE or orb != null)

	if obstructs(to, actor) and (actor != Actor.PARTICLE or not can_activate(to, orb)):
		return false
	elif is_lift(from) or is_lift(to):
		assert(not (is_lift(from) and is_lift(to)))

		var from_y := get_lift_bottom(from).y + int(is_lift_up(from))
		var to_y := get_lift_bottom(to).y + int(is_lift_up(to))
		assert( [0.0,1.0].has(abs(from_y - to_y)) )
		if actor == Actor.PARTICLE:
			# Particles can move to less or same y-pos
			return (from_y >= to_y)
		elif actor == Actor.PLAYER:
			# Player can *only* move to same y-pos
			return (from_y == to_y)

	return true

var _path_finding_thread = Thread.new()
func closest_reachable_path_for(actor: int, from: Vector3, to_closest: Vector3, orb=null, async:=false) -> String:
	var method := "_unwrap_shortest_path"
	var args := [actor, from, to_closest, orb]

	# Compute async signal name
	var salt := OS.get_ticks_msec()
	var signal_name := "shortest_path_found-%5d" % [salt+hash(args)]
	args.append(signal_name)

	if async:
		add_user_signal(signal_name, [TYPE_ARRAY])
		call_deferred(method, args)
		return signal_name
	else:
		return call(method, args)

func _unwrap_shortest_path(args: Array) -> PoolVector3Array:
	var signal_name := args[4] as String
	var path := _closest_reachable_path_for(args[0], args[1], args[2], args[3])

	if _DEBUG_:
		if path.size() >= 3:
			for cell in path: assert(Array(path).count(cell) == 1) # DEBUG
		for i in path.size()-2:
			assert(Array(edges(path[i])).has(path[i+1])) # DEBUG
	# FIXME: `path` should not return 2 items: [from, from] (`from = args[1]`)

	_notify(signal_name, [path])
	_notify("shortest_path_found", [path])
	return path

func _notify(signal_name: String, args:=[]):
	call_deferred("emit_signal", signal_name, args) # Main thread

class PointSorter:
	const to := [] # Use static var as cache

	static func set_to(value: Vector3):
		clear()
		to.append(value)

	static func sort(p1: Vector3, p2: Vector3) -> bool:
		assert(not to.empty())
		return p1.distance_to(to[0]) < p2.distance_to(to[0])

	static func clear():
		to.clear()

func _closest_edges(from: Vector3, to: Vector3) -> PoolVector3Array:
	var edges = Array(edges(from))
	PointSorter.set_to(to)
	edges.sort_custom(PointSorter, "sort")
	PointSorter.clear()
	return PoolVector3Array(edges)

#func _closest_reachable_path_for(actor: enum Actor, from: Vector3, to: Vector3, orb: Orb=null) -> [Vector3]
func _closest_reachable_path_for(actor: int, from: Vector3, to_closest: Vector3, orb=null) -> PoolVector3Array:
	assert(actor != Actor.PARTICLE or orb != null)

	if from == to_closest:
		return PoolVector3Array([from])

	var current := from
	var visited := [from]
	var closests := {} # {Vector3 : path:[Vector3]}
	var current_path := []
	while true:
		assert(current == from or not visited.has(current))
		visited.append(current)
		current_path.append(current)
		if current == to_closest: # End reachable and found
			return PoolVector3Array(current_path)

		var next# Vector3?
		for neighbor in _closest_edges(current, to_closest):
			if not visited.has(neighbor):
				if allow_reaching(actor, current, neighbor, orb):
					next = neighbor; break
				else:
					visited.append(neighbor)

		if next != null:
			if actor == Actor.PARTICLE and can_activate(next, orb):
				closests[next] = current_path + [next]
		else: # End / Obstructed
			closests[current] = [] + current_path

			current_path.pop_back()
			# Go back to last cell with unvisited edge cells
			while current_path.size() >= 1 and next == null:
				current = current_path.back(); current_path.pop_back()

				for neighbor in edges(current):
					if not visited.has(neighbor):
						if allow_reaching(actor, current, neighbor, orb):
							current_path.append(current)
							next = neighbor; break
						else:
							visited.append(neighbor)

			var is_start := current_path.empty()
			if is_start:
				# All directions starting at `from` visited
				if Helper.has_all(visited, edges(from)):
					break # Stop
				else:
					next = from # Start again from `from`

		assert(next != null)
		current = next

	assert(not closests.empty())
	# Return the path with the closest cell to `to_closest`
	var shortest_path: PoolVector3Array
	var min_distance := INF
	#prints("Closests:", closests.keys())
	for closest in closests:
		var path := path_for(Actor._HOLLOW, closest, to_closest)
		if path.size() < min_distance:
			min_distance = path.size()
			shortest_path = PoolVector3Array(closests[closest])

	if actor == Actor.PARTICLE:
		var direct_path := path_for(Actor._HOLLOW, from, to_closest)
		if direct_path.size() < min_distance:
			return PoolVector3Array([from])

	assert(shortest_path != null);
	return shortest_path

func rad2orientation(angle: float) -> int:
	var deg := rad2deg(wrapf(angle, 0,TAU))
	return { 0:0, 90:16, 180:10, 270:22 }[int(deg)]

func get_cell_quat(cell: Vector3) -> Quat:
	var orientation := get_cell_item_orientationv(cell)
	# @see Basis::get_orthogonal_index() in Godot source code
	var angle = { 0: 0, 10: PI, 16: PI/2, 22: -PI/2 }[orientation]
	return Quat(UP, angle)

func get_cell_aabb(cell: Vector3) -> AABB:
	var aabb := AABB()
	var item := get_cell_itemv(cell)
	var mesh := theme.get_item_mesh(item)
	if not mesh: return aabb# DEBUG
	for vertex in mesh.get_faces():
		aabb = aabb.expand(vertex)

	var rot := get_cell_quat(cell)
	return Transform(rot).xform(aabb)

func get_bounds(margin:=5) -> AABB:
	return get_bounds_margin_all(margin)

func get_bounds_margin_all(margin: float) -> AABB:
	var bounds := AABB()
	for cell in get_used_cells():
		if get_cell_aabb(cell).size.y >= 1.0:
			var aabb := AABB(cell, cell_size)
			bounds = bounds.merge(aabb)
	bounds.position -= Vector3(margin, 0, margin)
	bounds.size += Vector3(2*margin, 0, 2*margin)
	return bounds

## Extensions

func get_cells(item: int) -> PoolVector3Array:
	var cells = PoolVector3Array(); for cell in get_used_cells():
		if get_cell_itemv(cell) == item:
			cells.append(cell)
	return cells

func get_cells_for(type: int) -> PoolVector3Array:
	var cells := PoolVector3Array(); for cell in get_used_cells():
		if _item_type(get_cell_itemv(cell)) == type:
			cells.append(cell)
	return cells

func get_cell_itemv(cell: Vector3) -> int:
	return get_cell_item(cell.x, cell.y, cell.z)

func get_cell_item_orientationv(cell: Vector3) -> int:
	return get_cell_item_orientation(cell.x, cell.y, cell.z)

func set_cell_itemv(cell: Vector3, item: int, orientation:=0):
	set_cell_item(round(cell.x), round(cell.y), round(cell.z), item, orientation)

## DEPRECATED

# Returns false for disallowed path finding propagations `from` to `to` from `actor` constraints.
func allows_propagation(actor: int, from: Vector3, to: Vector3) -> bool:
	if is_stairs(from) or is_stairs(to):
		return true

	if actor == Actor.PLAYER:
		var y := get_lift_bottom(from).y + int(is_lift_up(from))
		var to_y := get_lift_bottom(to).y + int(is_lift_up(to))
		return not (y > to_y) # Player cannot go to lower level directly

	return true

# Returns the path `from` to `to` depending of `actor` propagation constraints.
#   This includes `from` and `to` if different and if path found, else path contains only `from`.
func path_for(actor: int, from: Vector3, to: Vector3) -> PoolVector3Array:
	assert(from != null and (is_walkable(from) or is_lift_up(from)))
	assert(to != null and (is_walkable(to) or is_lift_up(to)))

	if from == to:
		return PoolVector3Array([from])

	var queue := [from]
	var previous := {} # { current: Vector3 => previous: Vector3 }
	while not queue.empty():
		var current = queue.front(); queue.pop_front()
		for next in edges(current):
			if not previous.has(next) and allows_propagation(actor, current, next):
				queue.append(next)
				previous[next] = current

	# Get final path by transversing it
	var current := to
	var path := PoolVector3Array([to])
	while current != from:
		if not previous.has(current): break # DEBUG
		assert(previous.has(current))
		current = previous[current]
		path.append(current)
	path.invert()
	return path

## DEBUG

func fill_rect(image: Image, rect: Rect2, color: Color, margin:=0):
	if rect.size.x < 0:
		rect.position.x += rect.size.x; rect.size.x = -rect.size.x
	if rect.size.y < 0:
		rect.position.y += rect.size.y; rect.size.y = -rect.size.y
	rect = rect.grow(margin)

	#assert(0 <= rect.position.x and
	#	rect.position.x + rect.size.x <= image.get_size().x)
	#assert(0 <= rect.position.y and
	#	rect.position.y + rect.size.y <= image.get_size().y)

	image.lock()
	var ofs = rect.position
	for x in int(rect.size.x+1):
		for y in int(rect.size.y+1):
			image.set_pixel(round(ofs.x) + x, round(ofs.y) + y, color)
	image.unlock()

func round_rect(rect: Rect2) -> Rect2:
	rect.position.x = round(rect.position.x)
	rect.position.y = round(rect.position.y)
	rect.size.x = round(rect.size.x)
	rect.size.y = round(rect.size.y)
	return rect

func generate_distmap(only_bottom=false): # DEBUG
	if not ClassDB.can_instance("SSEDT8"): return null
	assert(_DEBUG_)
	var scale := Vector2(2, 2)
	var margin := 10

	var bounds := get_bounds(margin)
	var size := bounds.size * Vector3(scale.x, 1, scale.y)
	var origin := bounds.position

	var bottom := bounds.position.y
	var img := Image.new()
	img.create(size.x, size.z, false, Image.FORMAT_RGBA8)
	img.fill(Color(0,0,0))

	for cell in get_used_cells():
		if cell.y == bottom or not only_bottom:
			var aabb = get_cell_aabb(cell)
			var pos := Vector2(
				cell.x + aabb.position.x + 0.5 - origin.x,
				cell.z + aabb.position.z + 0.5 - origin.z) * scale
			var rect := Rect2(pos, Vector2(aabb.size.x, aabb.size.z) * scale)
			fill_rect(img, round_rect(rect), Color(1,1,1))

	img.resize(size.x * 2, size.z * 2, Image.INTERPOLATE_NEAREST)

	var map = ClassDB.instance("SSEDT8").from(img, 0.02)
	map.resize(size.x * 1, size.z * 1, Image.INTERPOLATE_BILINEAR)
	assert(map.generate_mipmaps() == OK)
	assert(not map.is_empty())
	return map
