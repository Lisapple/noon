extends Node

const DEBUG_ENABLED = false

static func test():
	var arr = [1,1,2,3,4,0,2,3,0]
	distinct(arr)
	assert(arr == [1,2,3,4,0])

	var dict = {"a": 1, "b": 2}
	assert(get(dict, "a", []) == 1)
	assert(get(dict, "c", 3) == 3)

	assert(first_match("abc(\\d{3})", "abc123") == "123")
	assert(first_match("abc(.)", "abde") == null)

	assert(has_all([1,3,2,4], [1,2]))
	assert(not has_all([1,2,3], [2,4]))

static func distinct(p_array):
	for e in []+p_array:
		if p_array.count(e) > 1:
			p_array.remove(p_array.find_last(e))
	return p_array

static func has_all(array, elements):
	for e in elements:
		if not array.has(e): return false
	return true

static func get(dict, key, default=null):
	return dict[key] if dict.has(key) else default

static func first_match(pattern, subject):
	var regex = RegEx.new(); assert(regex.compile(pattern) == OK)
	var matches = regex.search(subject)
	return matches.get_string(1) if matches else null

static func remove_from_parent(node, should_free=true):
	if node.is_inside_tree():
		if should_free: node.queue_free()
		node.get_parent().remove_child(node)

static func get_surface_named(mesh, name):
	assert(mesh is ArrayMesh)
	for index in mesh.get_surface_count():
		if mesh.surface_get_name(index) == name: return index
	return -1