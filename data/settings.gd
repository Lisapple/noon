extends Node

# settings.set("name", "Max")
# settings.set("age", 123)
# settings.remove("country")
# settings.save()
#
# settings.reload() # Force reloading from disk; this discards unsaved changes
# var name = settings.get("name")
# var age = settings.get("age")
# var country = settings.get("country") # country = null

const SETTINGS_PATH = "user://settings_v1.dat"
const SETTINGS_PASSCODE = null # Ignored if null

signal loaded()
signal updated(key, old_val, val) # updated(String, Variant?, Variant?)
signal saved()

# Save format: `key1 val1 key2 val2`, ex.: `4name 3Max 3age 123`
var content = {}

func _init():
	load_from_disk()
	#test() # DEBUG

func load_from_disk():
	var file = File.new()
	if file.file_exists(SETTINGS_PATH):
		if SETTINGS_PASSCODE:
			file.open_encrypted_with_pass(SETTINGS_PATH, File.READ, SETTINGS_PASSCODE)
		else:
			file.open(SETTINGS_PATH, File.READ)
		content = {}
		var key; while not file.eof_reached():
			var val = file.get_var(); if val == null: break # FIXME: `get_var()` show debug error if no more var to read from file
			if key == null: key = val
			else:
				content[key] = val; key = null
		file.close()
		emit_signal("loaded")

func reload(discard_changes=false): # TODO: support `discard_changes` (keep changes and re-add them after reloading if not already present) option
	load_from_disk()

func get(key):
	return content[key] if content.has(key) else null

func set(key, value):
	var old = get(key); content[key] = value
	emit_signal("updated", key, old, value)

func erase(key):
	remove(key)
func remove(key):
	var old = get(key); content.erase(key)
	if old != null:
		emit_signal("updated", key, old, null)

func save():
	var file = File.new()
	if SETTINGS_PASSCODE:
		file.open_encrypted_with_pass(SETTINGS_PATH, File.WRITE, SETTINGS_PASSCODE)
	else:
		file.open(SETTINGS_PATH, File.WRITE)
	for key in content:
		file.store_var(key); file.store_var(content[key])
	file.close()
	emit_signal("saved")

func test():
	set("test", 12); set("test", 123)
	assert(get("test") == 123)
	save()
	set("discarded", 234) # Discarded
	reload()
	assert(get("discarded") == null)
	assert(get("test") == 123)
	remove("test")
	assert(get("test") == null)
