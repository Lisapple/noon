tool
extends EditorImportPlugin

signal resource_saved(res, path)

func get_import_order():
	return 99

func get_importer_name():
	return "noon.mesh-library.import.plugin"

func get_visible_name():
	return "Mesh Library Importer"

func get_recognized_extensions():
	return ["dae"]

func get_save_extension():
	return "scn"

func get_resource_type():
	return "PackedScene"

func get_preset_count():
	return 0

func get_preset_name(i):
	return "Default"

func get_option_visibility(option, options):
	return false

func get_import_options(preset):
	return [
		{"name": "basename", "default_value": "ImportedMeshLib"},
		{"name": "use_unique_name", "default_value": true},
		{"name": "generate_previews", "default_value": true}
	]

func get_all_children(node, only_visible=true):
	var children = []
	for child in node.get_children():
		if child.get_child_count() > 0 and not child is Skeleton:
			children += get_all_children(child)
		elif child is Spatial and (child.visible or not only_visible):
			children.append(child)
	return children

func export_library(path, scene): # Return saved library path
	var library = MeshLibrary.new(); library.clear()
	var regex = RegEx.new(); assert(regex.compile("^(\\d+)([BGPRYN])?_(.+)") == OK) # 'N' prefix for Nightmare

	# Update tree for extras from:
	# [Root]
	# ┠╴Skeleton
	# ┃  ┖╴MeshInstance
	# ┠╴AnimationPlayer
	#
	# to:
	# [Root]
	# ┖╴MeshInstance # Need to update node path for `skeleton` property
	#    ┠╴Skeleton
	#    ┖╴AnimationPlayer # Keep on same level that "Skeleton" for tracks to be valid

	var player = scene.get_node("AnimationPlayer")
	var anim = player.get_animation_list()[0]
	player.get_animation(anim).loop = true
	player.autoplay = anim
	player.playback_speed = 0.45

	var extra_nodes = []
	for node in get_all_children(scene):
		if node is Skeleton:
			var skeleton = node
			var mesh = skeleton.get_child(0); assert(mesh and mesh is MeshInstance)
			scene.remove_child(skeleton)
			skeleton.remove_child(mesh)
			# Move skeleton and AnimationPlayer into MeshInstance
			mesh.skeleton = NodePath(skeleton.name)
			mesh.add_child(skeleton)
			mesh.add_child(player.duplicate())
			extra_nodes.append(mesh)

			# Keep MeshInstance for MeshLib
			node = mesh.duplicate(); scene.add_child(node)

		var m = regex.search(node.name, 0)
		if not m or not (node is MeshInstance): continue

		var id = int(m.get_string(1)); assert(id >= 0)
		var orb; var name
		if m.strings.size() == 4:
			orb = m.get_string(2); name = m.get_string(3)
		else:
			assert([2,3].has(m.strings.size()))
			name = m.strings.back()

		if Array(library.get_item_list()).has(id):
			print("*** Error: Duplicate item with `%d` named `%s`" % [id, library.get_item_name(id)])
			assert(library.get_item_mesh(id) != null) # Notice: Duplicate `id` value

		# Fix materials
		assert(node.mesh is ArrayMesh)
		for index in node.mesh.get_surface_count():
			var mat = node.mesh.surface_get_material(index)
			if not (mat and mat is SpatialMaterial): continue
			mat.flags_vertex_lighting = true
			mat.vertex_color_use_as_albedo = true
			mat.params_cull_mode = SpatialMaterial.CULL_BACK
			mat.params_specular_mode = SpatialMaterial.SPECULAR_DISABLED
			mat.roughness = 0

			# Params for reflection path/top-scenery
			#metallic = 0.3
			#specular = 0.5
			#roughness = 0.85

			var mat_name = node.mesh.surface_get_name(index)
			mat.flags_unshaded = (mat_name == "Path")
			node.mesh.surface_set_material(index, mat)

		# Setup wave materials
		var alpha = 0.35
		var wave_mat = preload("res://materials/WaveShader.tres")
		match name:
			"Wave-Straight", "Wave-Exterior", "Wave-Interior":
				var type = ["Wave-Straight", "Wave-Exterior", "Wave-Interior"].find(name)
				var mat = wave_mat.duplicate()
				mat.set_shader_param("type", type)
				mat.set_shader_param("alpha", alpha)
				node.mesh.surface_set_material(0, mat)
			"Wave-Plain":
				var mat = SpatialMaterial.new()
				#mat.flags_unshaded = true
				mat.flags_transparent = true
				mat.albedo_color = Color(1,1,1, alpha)
				node.mesh.surface_set_material(0, mat)

		library.create_item(id)
		var cell_name = ("%s-%s" % [orb, name]) if orb else name
		library.set_item_name(id, cell_name)
		library.set_item_mesh(id, node.mesh)

		print("### Added to library: %d @ \"%s\" (from `%s`)" % [id, cell_name, scene.get_path_to(node)])

	# Save new scene with extra nodes
	var root = Node.new()
	for node in extra_nodes:
		assert(not node.get_parent())
		root.add_child(node); node.owner = root
		for child in node.get_children(): child.owner = root

	var extra = PackedScene.new(); assert(extra.pack(root) == OK)
	var extra_path = "res://models/ImportedExtras.tscn"
	root.print_tree_pretty()
	assert(ResourceSaver.save(extra_path, extra) == OK)
	print("### Saved extras as %s" % extra_path)

	# Save mesh library
	var path_format = "res://models/%s_%d.meshlib"
	var filename = "ImportedMeshLib"; var suffix = 2;
	while File.new().file_exists(path_format % [filename, suffix]):
		suffix += 1
	var final_path = path_format % [filename, suffix]
	print("### Saved as %s" % final_path)
	assert(ResourceSaver.save(final_path, library) == OK)

	library.take_over_path(final_path)

	emit_signal("resource_saved", library, final_path)
	return final_path

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var scene = load(source_file).instance()
	var lib_path = export_library("", scene)
	r_gen_files += [source_file, lib_path]
	return OK
