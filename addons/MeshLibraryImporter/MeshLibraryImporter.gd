tool
extends EditorPlugin

var import_plugin

func _enter_tree():
	import_plugin = preload("MeshLibraryImporterPlugin.gd").new()
	import_plugin.connect("resource_saved", self, "_on_resource_saved")
	add_import_plugin(import_plugin)

func _on_resource_saved(library: MeshLibrary, path: String):
	var size := 64#px
	for item in library.get_item_list():
		var mesh := library.get_item_mesh(item)
		var preview = get_editor_interface().make_mesh_previews([mesh], size)[0]
		library.set_item_preview(item, preview)

	var err := ResourceSaver.save(path, library); assert(err == OK)

	# Success alert
	var alert := AcceptDialog.new()
	alert.window_title = "Library successfully exported!"
	alert.dialog_text = "Saved as %s" % path
	alert.popup_exclusive = true
	# TODO: Focus on OK button and set as modal
	#alert.get_ok().focus_mode = Control.FOCUS_ALL
	#alert.get_ok().grab_click_focus()
	#alert.show_modal(true)
	get_editor_interface().get_base_control().add_child(alert)
	alert.popup_centered()

func _exit_tree():
	print("_exit_tree")
	import_plugin.disconnect("resource_saved", self, "_on_resource_saved")
	remove_import_plugin(import_plugin)
	import_plugin.free()
