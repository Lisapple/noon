# Subclass of AudioStreamPlayer, with mute setting.
# Used in `GameGridMap.gd` to play sounds.
extends "res://MuteSamplePlayer.gd"

class _AudioPlayer extends "res://MuteSamplePlayer.gd":

	var sound # enum Sound!

	func _init():
		set_bus_name(BUS_NAME)
		set_settings_name(SETTING_NAME)

	func play(position=0):
		assert(sound != null)
		assert(is_inside_tree())

		var name = Sound.name(sound)
		stream = load("res://sounds/%s.wav" % name)
		.play(position)

const SETTING_NAME = "sounds_player"
const BUS_NAME = "sound-player"
const LOW_FREQ = 680#Hz

var nightmare = false setget set_nightmare, is_nightmare
func is_nightmare():
	return nightmare
func set_nightmare(enabled):
	nightmare = enabled
	var bus = AudioServer.get_bus_index(BUS_NAME)
	AudioServer.set_bus_effect_enabled(bus, 0, nightmare)

func _init():
	set_bus_name(BUS_NAME)
	set_settings_name(SETTING_NAME)

	var bus = AudioServer.get_bus_index(BUS_NAME)
	var effect = AudioEffectLowPassFilter.new()
	effect.cutoff_hz = LOW_FREQ
	effect.db = AudioEffectFilter.FILTER_12DB
	AudioServer.add_bus_effect(bus, effect)
	AudioServer.set_bus_effect_enabled(bus, 0, false)

func _get_players():
	var players := []
	for child in get_children():
		if child is _AudioPlayer: players.append(child)
	return players

func _player_for(sound: int):
	for player in _get_players():
		if player.sound == sound and player.playing: return player

func _get_ready_player() -> _AudioPlayer:
	var player = _AudioPlayer.new(); add_child(player)
	player.bus = BUS_NAME
	return player

func play_sound(sound: int):
	assert(is_inside_tree())
	prints("$$$ Playing:", Sound.name(sound))

	var player := _get_ready_player()
	player.sound = sound
	player.play()

func stop_sound(sound: int):
	if _player_for(sound):
		_player_for(sound).stop()
	#cleanup_players() # TODO: Cleanup players sometime

func cleanup_players():
	for player in []+_get_players():
		if not player.playing:
			player.queue_free(); remove_child(player)
