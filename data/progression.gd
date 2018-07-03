extends Node

### Save format:
# ```
#   i8: format_version,
#   str: "current level name",
#   str: "start name",
#   i8: has_blue, has_green, has_purple, has_red, has_yellow,
#   str: "last death level" ("" if none)
#  ```
# like so: `4 7Level10 5Start 1 1 0 0 0 6Level1`

### Constants

const SAVE_PATH = "user://noon-save.dat"
const SAVE_PASSCODE = "noooOOOooon"
const SAVE_VERSION = 1

### Variables

var start_name # String?
var current_level setget set_current_level # String?
func set_current_level(level, start=null):
	current_level = level
	start_name = start
	save()
var last_nightmare_level setget set_nightmare_level # String?
func set_nightmare_level(level):
	last_nightmare_level = level
	save()

var available_orbs = [] setget set_available_orbs, get_available_orbs # [enum Orb]
func get_available_orbs():
	return available_orbs
func set_available_orbs(orbs):
	assert(typeof(orbs) == TYPE_ARRAY)
	available_orbs = orbs
	save()

func _init():
	load_from_disk()

func load_from_disk():
	var file = File.new()
	if file.file_exists(SAVE_PATH):
		file.open_encrypted_with_pass(SAVE_PATH, File.READ, SAVE_PASSCODE)
		if file.get_8() != SAVE_VERSION:
			delete(true); return

		current_level = file.get_var()
		start_name = file.get_var()
		available_orbs = []
		for orb in [Orb.BLUE, Orb.GREEN, Orb.PURPLE, Orb.RED, Orb.YELLOW]:
			if file.get_8() != 0: add_available_orb(orb)
		last_nightmare_level = file.get_var()
		file.close()

func set_level(level):
	current_level = level

func add_available_orb(orb):
	if not available_orbs.has(orb):
		available_orbs.append(orb)

func save():
	if current_level != null and available_orbs != null:
		var file = File.new()
		file.open_encrypted_with_pass(SAVE_PATH, File.WRITE, SAVE_PASSCODE)
		file.store_8(SAVE_VERSION)
		file.store_var(current_level if current_level else "")
		file.store_var(start_name if start_name else "") # FIXME: This asserts if the string is empty
		for orb in [Orb.BLUE, Orb.GREEN, Orb.PURPLE, Orb.RED, Orb.YELLOW]:
			file.store_8(int(available_orbs.has(orb)))
		file.store_var(last_nightmare_level if last_nightmare_level else "")
		file.close()

func delete(confirm=false):
	if confirm:
		var file = File.new()
		file.open_encrypted_with_pass(SAVE_PATH, File.WRITE, SAVE_PASSCODE)
		file.store_var(null)
		file.close()
		current_level = null
		start_name = null
		last_nightmare_level = null
		available_orbs = []
