extends "res://MuteSamplePlayer.gd"

var _DEBUG_ = Helper.DEBUG_ENABLED

class OceanPlayer extends AudioStreamPlayer:

	func _init():
		var name = Sound.name(Sound.OCEAN)
		#stream = load("res://sounds/%s.wav" % name) # DEBUG

var FOLDERS = {
	Season.SUMMER: "summer", Season.AUTUMN: "autumn", Season.WINTER: "winter", Season.SPRING: "spring"
}
var THEMES = {
	Season.SUMMER: ["theme-1", "theme-2", "theme-3", "theme-4"],
	Season.AUTUMN: ["theme-1", "theme-2", "theme-3", "theme-4"],
	Season.WINTER: ["theme-1", "theme-2", "theme-3", "theme-4"],
	Season.SPRING: ["theme-1", "theme-2", "theme-3", "theme-4", "theme-5"]
}
var BRIDGES = {
	Season.SUMMER: ["bridge-1", "bridge-2", "bridge-3", "bridge-4"],
	Season.AUTUMN: ["bridge-1", "bridge-2", "bridge-3", "bridge-4"],
	Season.WINTER: ["bridge-1", "bridge-2", "bridge-3", "bridge-4"],
	Season.SPRING: ["bridge-1", "bridge-2", "bridge-3", "bridge-4"]
}

const BUS_NAME = "background-music-player"
const NIGHTMARE_PLAYS_MUSIC = true # If music should not be muted on nightmare mode

var current_season # enum Season?
var current_theme # String, from THEMES
var current_bridge # String, from BRIGES
var current_sample
var timer = Timer.new()

var ocean_player = OceanPlayer.new()

func _init():
	set_bus_name(BUS_NAME)
	set_settings_name("music_player")

	var bus = AudioServer.get_bus_index(BUS_NAME)
	AudioServer.set_bus_volume_db(bus, -3.6)
	AudioServer.set_bus_mute(bus, is_muted())

	var filter = AudioEffectLowPassFilter.new()
	filter.cutoff_hz = 960#Hz
	AudioServer.add_bus_effect(bus, filter)
	AudioServer.set_bus_effect_enabled(bus, 0, false)

	var reverb = AudioEffectReverb.new()
	AudioServer.add_bus_effect(bus, reverb)
	AudioServer.set_bus_effect_enabled(bus, 1, false)

func _ready():
	add_child(timer)
	add_child(ocean_player)
	set_season(Season.SUMMER)
	connect("player_muted", self, "_on_muted")

func set_season(season, nightmare=false):
	assert(not THEMES[season].empty())
	assert(not BRIDGES[season].empty())
	if current_season != season:
		current_season = season
		current_theme = THEMES[season].front()
		current_bridge = BRIDGES[season].front()
		var bus = AudioServer.get_bus_index(BUS_NAME)
		if NIGHTMARE_PLAYS_MUSIC:
			AudioServer.set_bus_effect_enabled(bus, 0, nightmare)
			AudioServer.set_bus_effect_enabled(bus, 1, nightmare)
		else:
			AudioServer.set_bus_mute(bus, nightmare)

		play_loop_for(season)

func _rand_theme(season):
	var themes = THEMES[season]
	var index = themes.find(current_theme); assert(index != -1)
	index = (index + randi() % themes.size()) % themes.size()
	return themes[index]

func _rand_bridge(season):
	var bridges = BRIDGES[season]
	var index = bridges.find(current_bridge); assert(index != -1)
	index = (index + randi() % bridges.size()) % bridges.size()
	return bridges[index]

func play_loop_for(season):
	assert(is_inside_tree())
	stop()
	var sample = current_theme
	if stream:
		var name = stream.resource_path.get_file().get_basename()
		var playing_theme = THEMES[season].has(name)
		sample = (_rand_bridge(season) if playing_theme else _rand_theme(season))

	var folder = Season.name(season).to_lower()
	stream = load("res://music/%s/%s.wav" % [folder, sample])

	if is_connected("finished", self, "play_loop_for"):
		disconnect("finished", self, "play_loop_for")
	connect("finished", self, "play_loop_for", [season])
	play()

func _on_muted(muted):
	ocean_player.playing = muted # Play ocean sounds if no music