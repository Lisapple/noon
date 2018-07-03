extends AudioStreamPlayer

# Note: Subclasses must call `set_bus_name` then `set_settings_name` before first save.

signal player_muted(muted)

func set_bus_name(value):
	AudioServer.add_bus(); var bus = AudioServer.get_bus_count()-1
	AudioServer.set_bus_name(bus, value)
	AudioServer.set_bus_send(bus, AudioServer.get_bus_name(0)) # Send to master
	self.bus = value

var settings_name setget set_settings_name
func set_settings_name(name):
	assert(AudioServer.get_bus_index(self.bus) != 0)
	settings_name = "%s_mute" % name
	var muted = settings.get(settings_name)
	if muted != null: set_muted(muted, false)

var muted = false setget set_muted, is_muted
func is_muted():
	return muted
func set_muted(value, save=true):
	muted = value
	var index = AudioServer.get_bus_index(self.bus); assert(index != 0)
	AudioServer.set_bus_mute(index, value)
	if save: save()
	emit_signal("player_muted", muted)

func save():
	assert(settings_name)
	settings.set(settings_name, is_muted())
	settings.save()