extends AnimationPlayer

### Signals

signal all_animation_finished

var pool = [] # Pool of animation players, for mutliple `play` calls at the same time
var backward_animations = []

func _ready():
	connect("animation_finished", self, "_on_animation_finished")
	# Remove children used as placeholder for level animations
	for node in []+get_children():
		node.queue_free(); remove_child(node)

func play(name="", custom_blend=-1, custom_speed=1.0, from_end=false):
	assert(get_animation(name))
	backward_animations.erase(name)
	var player = get_idle_player(); if player:
		player.add_animation(name, get_animation(name))
		player.play(name, custom_blend, custom_speed, from_end)
	else: .play(name, custom_blend, custom_speed, from_end)

func play_backwards(name="", custom_blend=-1):
	assert(get_animation(name))
	backward_animations.append(name)
	var player = get_idle_player(); if player:
		player.add_animation(name, get_animation(name))
		player.play_backwards(name, custom_blend)
	else: .play_backwards(name, custom_blend)

func seek(name, pos_sec, stop=true, update=true):
	.play(name)
	if get_current_animation() == name:
		.seek(pos_sec, update)
		if stop: .stop()
	else:
		for player in pool: # Find active player for `name`
			if player.get_current_animation() == name:
				player.seek(pos_sec, update)
				if stop: player.stop()
				break

func remove_animation(name):
	if .has_animation(name):
		.remove_animation(name)
	for player in pool:
		if player.has_animation(name):
			player.remove_animation(name)

#func seek(pos_sec, update=false)
#stop(reset=true)

# Returns a non-playing player, or null if self is idle.
func get_idle_player():
	if player_is_idle(self): return null
	for player in pool:
		if not player.is_playing() and not next_animation_for(player):
			return player # Returns from pool
	# Create new one in the pool
	var player = AnimationPlayer.new(); player.name = "player-pool"
	player.connect("animation_finished", self, "_on_animation_finished")
	pool.append(player); get_parent().add_child(player, true)
	return player

func _cleanup_pool():
	for player in []+pool: if not player.is_playing():
			pool.erase(player); player.stop(true)
			player.queue_free(); player.get_parent().remove_child(player)

func player_is_idle(player):
	var name = player.current_animation
	var ignores = idle_ignores_animation(name)
	var will_play = (name and player.current_animation_position == 0)
	if name and backward_animations.has(name):
		will_play = (player.current_animation_position == player.current_animation_length)
	# Note: if `will_play` true, the animation hasn't started yet (the player hasn't started neither if not playing)
	var is_active = (player.is_playing() or will_play) and not ignores
	return (not is_active and not next_animation_for(player))

func next_animation_for(player):
	var name = player.get_current_animation()
	if name and not animation_get_next(name):
		return animation_get_next(name)
	return null

func idle_ignores_animation(name):
	var animation
	if has_animation(name):
		animation = get_animation(name)
	for player in pool:
		if player.has_animation(name):
			animation = player.get_animation(name)
	return not animation or animation.has_loop()

# Returns true if all animations are finished and no more queued.
func is_idle():
	var active_players = [] # DEBUG
	var is_idle = true; for player in [self]+pool:
		is_idle = is_idle and player_is_idle(player)
		if not player_is_idle(player): active_players.append({player : player.get_current_animation()})
	return is_idle

func _on_animation_finished():
	if not is_idle(): call_deferred("_on_animation_finished"); return
	emit_signal("all_animation_finished")
	_cleanup_pool()
