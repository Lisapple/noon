extends Node

const DEBUG_ENABLED = false # Switch to DEBUG mode

static func test():
	var arr := [1,1,2,3,4,0,2,3,0]
	var _arr := distinct(arr)
	assert(arr == [1,2,3,4,0])
	assert(_arr == arr)

	assert(first_match("abc(\\d{3})", "abc123") == "123")
	assert(first_match("abc(.)", "abde") == null)

	assert(has_all([1,3,2,4], [1,2]))
	assert(not has_all([1,2,3], [2,4]))

static func distinct(p_array: Array) -> Array:
	for e in []+p_array:
		if p_array.count(e) > 1:
			p_array.remove(p_array.find_last(e))
	return p_array

static func has_all(array: Array, elements: Array) -> bool:
	for e in elements:
		if not array.has(e): return false
	return true

static func first_match(pattern: String, subject: String) -> String:
	var regex := RegEx.new();
	var err := regex.compile(pattern); assert(err == OK)
	var matches := regex.search(subject)
	return matches.get_string(1) if matches else null

static func remove_from_parent(node: Node, should_free:=true):
	if node.is_inside_tree():
		if should_free: node.queue_free()
		node.get_parent().remove_child(node)

static func get_surface_named(mesh: ArrayMesh, name: String) -> int:
	for index in mesh.get_surface_count():
		if mesh.surface_get_name(index) == name: return index
	return -1