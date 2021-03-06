extends "res://_GridMap.gd"

var PLAYER_SPEED := 2.5 if _DEBUG_ else 1.4
var PLAYER_OFFSET := AREA_OFFSET + Vector3(0,0.5,0)

class Player extends Spatial:

	enum ANIMS {
		ABSORB, # Take/place the orb from/into its bag
		ABSORB_NONE, # Look at the orb like it doesn't work
		RELEASE, # Take/place the orb from/into its bag
		RELEASE_NONE, # Look at the orb like it doesn't work
		START, STOP, # Start/stop walking/running, for the first/last cell
		WALK, RUN, # Run if > 3 blocks away (always looping)
		TURN_LEFT, TURN_RIGHT, HALF_TURN, # Turn +90º, -90º or +180º
		ASCEND, DESCEND, # Climb/descend stairs
		ASCEND_LIFT, DESCEND_LIFT,
		TAKE, # Lean to take orb
		STAND_UP, # Player stand up for Intro
		IDLE # Default pose
	}

	var ANIMATIONS := {
		ANIMS.ABSORB: "Using orb", ANIMS.ABSORB_NONE: "Cannot using orb",
		ANIMS.RELEASE: "Using orb", ANIMS.RELEASE_NONE: "Cannot using orb",
		ANIMS.START: "Start running", ANIMS.STOP: "Stop running",
		ANIMS.WALK: "Walking", ANIMS.RUN: "Running",
		ANIMS.TURN_LEFT: "Turn running", ANIMS.TURN_RIGHT: "Turn running", ANIMS.HALF_TURN: "Half turn",
		ANIMS.ASCEND: "Ascending stairs", ANIMS.DESCEND: "Descending stairs",
		ANIMS.ASCEND_LIFT: "Ascending Lift", ANIMS.DESCEND_LIFT: "Descending Lift",
		ANIMS.TAKE: "Getting orb",
		ANIMS.STAND_UP: "Stand up",
		ANIMS.IDLE: "Idle"
	}
	var WAIT_PREFIX := "Waiting "
	var WAITING_ANIMATIONS := {
		Season.SUMMER: [ WAIT_PREFIX+"Summer", WAIT_PREFIX+"Summer 2" ],
		Season.AUTUMN: [ WAIT_PREFIX+"Autumn", WAIT_PREFIX+"Autumn 2" ],
		Season.WINTER: [ WAIT_PREFIX+"Winter", WAIT_PREFIX+"Winter 2" ],
		Season.SPRING: [ WAIT_PREFIX+"Spring", WAIT_PREFIX+"Spring 2" ]
	}

	const ANIM_DURATIONS := { } # Duration with corrected speed
	func duration(anim: int) -> float:
		assert(ANIM_DURATIONS.has(anim))
		return ANIM_DURATIONS[anim] / float(speed_factor)

	var ANIM_SPEED := {
		ANIMS.ABSORB: 1.3, ANIMS.ABSORB_NONE: 0.6,
		ANIMS.RELEASE: 1.3, ANIMS.RELEASE_NONE: 0.6,
		ANIMS.START: 1.4, ANIMS.STOP: 1.4,
		ANIMS.WALK: 1.2, ANIMS.RUN: 1.4,
		ANIMS.TURN_LEFT: 1.4, ANIMS.TURN_RIGHT: 1.4,
		ANIMS.ASCEND: 1.5, ANIMS.DESCEND: 1.5
	}
	func _speed(anim) -> float:
		if anim == null: return 1.0
		assert(anim is int)
		return (ANIM_SPEED[anim] if ANIM_SPEED.has(anim) else 1.0) * speed_factor

	func name(anim: int) -> String:
		assert(ANIMATIONS.has(anim))
		return ANIMATIONS[anim]

	var animation_player: AnimationPlayer setget ,get_animation_player
	func get_animation_player() -> AnimationPlayer:
		return animation_player

	var season: int = Season.SUMMER setget set_season
	func set_season(value: int):
		season = value
		_update()

	var blend_enabled := true setget set_blend_enabled
	func set_blend_enabled(value: bool):
		blend_enabled = value
		if animation_player:
			animation_player.playback_default_blend_time = 0.2 if value else 0

	var speed_factor := 1.0 setget set_speed_factor
	func set_speed_factor(value: float):
		speed_factor = value
		if animation_player:
			animation_player.playback_speed = value

	var default_tween := Tween.new() setget ,get_default_tween
	func get_default_tween() -> Tween:
		return default_tween

	func _ready():
		name = "Player"

		var node := preload("res://models/player.dae").instance()
		node.rotation.y = PI
		add_child(node)

		if node.has_node("Lift"):
			node.remove_child(node.get_node("Lift")) # DEBUG

		animation_player = node.get_node("AnimationPlayer")
		animation_player.connect("animation_started", self, "_on_animation_started")

		# Add animation blending
		set_blend_enabled(blend_enabled)
		var transitions := [
			[ANIMS.START, ANIMS.RUN],
			[ANIMS.RUN, ANIMS.RUN],
			[ANIMS.RUN, ANIMS.STOP]
		]
		for anims in transitions:
			animation_player.set_blend_time(name(anims[0]), name(anims[1]), 0.0)

		# Adjust animations speed
		set_speed_factor(speed_factor)
		for anim in ANIMS.values():
			var animation := animation_player.get_animation(name(anim)); assert(animation)
			ANIM_DURATIONS[anim] = animation.length / _speed(anim)

		default_tween.name = "Tween"
		add_child(default_tween)
		_update()

	func _update():
		if not is_inside_tree(): return

		# Import new skeleton
		var model := preload("res://models/Season player.dae").instance()
		var skeleton = model.get_node("Skeleton"); assert(skeleton)
		skeleton.get_parent().remove_child(skeleton)
		# Remove all seasons except `season` from `skeleton`
		for child in []+skeleton.get_children():
			if child.name != Season.name(season):
				child.queue_free(); skeleton.remove_child(child)
		assert(skeleton.get_child_count() == 1)
		var torso = skeleton.get_child(0)
		torso.name = "Torso" # Rename to match animation paths

		# Fix materials properties
		for i in torso.mesh.get_surface_count()-1:
			var mat = torso.get_surface_material(i); assert(mat is SpatialMaterial)
			mat.roughness = 0.8

		# Replace old skeleton (after removing "Torso" child node)
		var root := get_child(0)
		var old_skeleton = root.get_node("Skeleton")
		var old_torso = old_skeleton.get_child(0); assert(old_torso.name == "Torso")
		old_skeleton.remove_child(old_torso)
		old_skeleton.replace_by(skeleton)

	func reset_skeleton_translation():
		var root = get_child(0)
		var skeleton = root.get_node("Skeleton")
		var index = skeleton.find_bone("Skeleton")
		var t = skeleton.get_bone_pose(index)
		skeleton.set_bone_pose(index, t.translated(-t.origin))

	func _on_animation_started(anim_name: String):
		assert(get_animation_player().current_animation_position < 1e-3)

		var name: int; for key in ANIMATIONS:
			if ANIMATIONS[key] == anim_name: name = key
		get_animation_player().playback_speed = _speed(name)

	func play_waiting():
		var anims := WAITING_ANIMATIONS[season] as Array
		var index := randi() % anims.size()
		var anim = anims[index]
		get_animation_player().play(anim)

	func stop_waiting():
		var player := get_animation_player()
		if player.current_animation.begins_with(WAIT_PREFIX):
			player.stop(false) # Stop only waiting animation

var Anim = Player.ANIMS

const Activable = preload("res://Activable.gd")
const OrbPanel = preload("res://OrbPanel.tscn")
const SoundPlayer = preload("res://SoundPlayer.gd")
const GameCamera = preload("res://GameCamera.gd")

signal player_hurt()

signal end_accessible(end_name) # The Player can walk to `end_name`
signal end_reached(end_name) # Player is going to `end_name` cell (emitted just before `finished`)

signal finished(end_name) # Player on `end_name` cell
signal failed() #
signal game_restarted() #

signal _spots_updated(spots)
signal _anim_finished(anim)

const ANIM_DONE_SIGNAL = "_anim_finished"

var END_NAMES = { # Use `get_end_names()` instead
	"Level30": ["End-G", "End-R"],
	"*": ["End"]
}
# Returns the cell where the player start the level (can be an end if from previous level).
func get_begin():
	var begin = get_start()
	var index = get_end_names().find(start_name)
	if index != -1: begin = get_ends()[index]
	return begin

var camera := GameCamera.new()
var audio_player := SoundPlayer.new()
var orb_panel := OrbPanel.instance()
var default_light := DirectionalLight.new()
var secondary_light := DirectionalLight.new()
var player := Player.new()

var start_name := START_NAME setget set_start
func set_start(name: String):
	start_name = name

var ambience: int = Ambience.DEFAULT setget set_ambience
func set_ambience(value: int):
	ambience = value
	assert(camera)
	camera.set_default_environment(ambience)
	_update_path_color()
	_update_music_player()

func _get_item_surface(item_name: String, surface_name: String) -> SpatialMaterial:
	var item := self.mesh_library.find_item_by_name(item_name)
	var mesh := self.mesh_library.get_item_mesh(item) as ArrayMesh
	var surface := Helper.get_surface_named(mesh, surface_name); assert(surface != -1)
	return mesh.surface_get_material(surface) as SpatialMaterial

func _update_path_color():
	var nightmare := (ambience == Ambience.NIGHTMARE)
	var color = Season.path_color(season)
	if nightmare:
		color = color.lightened(0.25); color.s *= 2.0
	
	var mat := _get_item_surface(PATH_PREFIX, "Path")
	mat.albedo_color = color
	
	# Fix start and ends material path
	for name in [START_NAME, END_NAME, END_2_NAME]:
		var item := self.mesh_library.find_item_by_name(name)
		var mesh := self.mesh_library.get_item_mesh(item) as ArrayMesh
		mesh.surface_set_material(0, mat)

var inactive_particles = {} # { cell:Vector3 : InactiveParticles }
func _add_inactive_particles(season):
	for lift in get_lifts():
		var particles = load("res://particles/LiftParticles.tscn").instance()
		inactive_particles[lift] = particles
	for door in get_doors():
		var particles = load("res://particles/DoorParticles.tscn").instance()
		inactive_particles[door] = particles
	for hole in get_holes():
		var particles = load("res://particles/HoleParticles.tscn").instance()
		inactive_particles[hole] = particles

	for activable in inactive_particles:
		var rot = get_cell_quat(activable)
		var particles = inactive_particles[activable]
		particles.transform *= Transform(rot)
		particles.translation = activable + NODE_OFFSET + Vector3(0,0.5,0)
		add_child(particles)
		var orb = get_cell_orb(activable)
		particles.set_orb(orb, season)

func _get_tree_items():
	var prefix = "Tree"
	var items = []; for cell in get_used_cells():
		var item = get_cell_itemv(cell)
		if self.mesh_library.get_item_name(item).begins_with(prefix):
			items.append(item)
	return items

func _get_trees():
	var items = _get_tree_items()
	var trees = []; for cell in get_used_cells():
		if items.has(get_cell_itemv(cell)):
			trees.append(cell)
	return trees

func _replace_trees_season(season):
	var trees = _get_trees()
	if season == Season.SPRING or trees.empty(): return

	var new_name = "Tree-%s" % Season.name(season)
	var extras = load("res://models/ImportedExtras.tscn").instance()
	var tree = extras.find_node("*_"+new_name, false); assert(tree)
	Helper.remove_from_parent(tree)

	for cell in trees:
		var rot = get_cell_quat(cell)
		var node = tree.duplicate()
		node.transform *= Transform(rot)
		node.translation = cell + NODE_OFFSET
		add_child(node)

		set_cell_itemv(cell, GridMap.INVALID_CELL_ITEM)

var snow # SnowParticles?
var season = Season.SUMMER setget set_season
func set_season(value):
	season = value

	if season == Season.WINTER and not snow:
		var SnowParticles = load("res://particles/Snow.tscn")
		snow = SnowParticles.instance()
		add_child(snow); move_child(snow, orb_panel.get_index())
		snow.emitting = true

	_update_path_color()
	var SCENERY_NAME = "Straight-2"
	_get_item_surface(SCENERY_NAME, "Scenery-top").albedo_color = Season.scenery_color(value)
	var PLANTS_SCENERY_NAME = "Straight-6"
	_get_item_surface(PLANTS_SCENERY_NAME, "Plants").albedo_color = Season.plants_color(value)
	#var TORCH_BLUE = "B-Torch"
	#_set_item_surface_color(TORCH_BLUE, "Torch-2", Color(0,0,0))

	var nightmare = (ambience == Ambience.NIGHTMARE)

	# Update activable material color
	var orb_names = {
		Orb.BLUE: "Blue", Orb.GREEN: "Green", Orb.PURPLE: "Purple",
		Orb.RED: "Red", Orb.YELLOW: "Yellow", Orb.GRAY: "Gray" }
	for orb in orb_names:
		var name = "%s-%s" % [Orb.prefix(orb), SUFFIXES[Type.TORCH]] # Torch item name
		var orb_name = orb_names[orb] # Orb material name
		var mat = _get_item_surface(name, orb_name)

		var color = Orb.color(orb, season)
		if nightmare: color = color.darkened(0.7)
		mat.albedo_color = color
		mat.flags_unshaded = nightmare

	_add_inactive_particles(season)
	_replace_trees_season(season)
	_update_music_player()

func _update_music_player():
	music_player.set_season(season, ambience == Ambience.NIGHTMARE)

func set_input_enabled(enabled):
	orb_panel.enabled = enabled
	if not enabled:
		for spot in get_spots(): enable_hotspot(spot, false)
	else:
		reload_spots()

func _test_level_integrity():
	Helper.test()
	var start = get_start()
	assert( start )
	assert( [1,2].has(get_ends().size()) )
	assert( camera is GameCamera )
	#assert( self.mesh_library.resource_path == "res://models/ImportedMeshLib_8.meshlib" )
	# Check that two activables are *not* neighboors
	var activables = get_activables() + get_orbs()
	for activable in activables:
		for neighbor in _neighbors(activable):
			assert(not Array(activables).has(neighbor))
	# Check that items exist in library (and here are no path extension)
	for cell in get_used_cells():
		var item = get_cell_itemv(cell)
		assert(Array(self.mesh_library.get_item_list()).has(item))
		assert(self.mesh_library.get_item_mesh(item))
		assert(item != PATH_EXT) # Notice: Remove all path extensions from grid
	# Check the reachability of all cells
	for cell in get_used_cells():
		if is_walkable(cell) and cell != start:
			assert( path_for(Actor._HOLLOW, cell, start).size() >= 2 )
	# Check that holes have only path same-level neighbors
	for hole in get_holes():
		for neighboor in edges(hole):
			var item = get_cell_itemv(neighboor)
			assert( self.mesh_library.get_item_name(item).begins_with(PATH_PREFIX) )
			assert( neighboor.y == hole.y )

func _ready():
	add_child(camera)
	
	get_viewport().connect("size_changed", self, "_on_frame_changed")
	call_deferred("start")

func _on_frame_changed():
	if snow: snow.position.x = get_viewport().size.x / 2

func get_walk_angle(from): # The angle (radians) to walkable cell next to `from`
	if _DEBUG_:
		var ns = 0; for n in _neighbors(from): ns += int(is_walkable(n)); assert(ns == 1) # DEBUG

	var next; for cell in _neighbors(from):
		if is_walkable(cell):
			next = cell; break
	return atan2(from.x-next.x, from.z-next.z)

var _level_angle
func get_level_angle(): # Get angle (radians) to player's back (i.e. first move to the top-right)
	if _level_angle == null:
		_level_angle = get_walk_angle(get_start())
	return _level_angle

func start():
	cell_scale = 1+1e-3 # Fixing cells aliasing

	var is_nightmare = name.begins_with("Nightmare")
	self.ambience = Ambience.NIGHTMARE if is_nightmare else Ambience.DEFAULT
	self.season = season # Force color theme once loaded

	connect("_spots_updated", self, "_on_spots_updated")
	connect("end_accessible", self, "_on_end_accessible")

	add_child(player)
	player.translation = get_begin() + PLAYER_OFFSET
	player.rotation.y = get_walk_angle(get_begin())
	player.speed_factor = PLAYER_SPEED
	player.season = season

	add_child(audio_player)

	if _DEBUG_: _test_level_integrity()

	randomize()
	init_path_extension()
	init_ocean()
	setup_camera()
	setup_torchs()
	setup_activables()

	var basename = filename.get_file().get_basename()
	if _DEBUG_: OS.set_window_title("[DEBUG] Noon – %s" % basename) # DEBUG
	init_orb_levels(basename)
	for orb in progression.available_orbs:
		orbs[orb] = orbs.get(orb, 0)

	if _DEBUG_:
		var shown_orb = [Orb.BLUE, Orb.GREEN, Orb.PURPLE, Orb.RED]
		for orb in shown_orb: add_orb_level(orb) # DEBUG

	add_child(orb_panel)
	orb_panel.ambience = ambience
	orb_panel.orb_levels = orbs
	orb_panel.connect("absorbed", self, "start_absorbing")
	orb_panel.connect("released", self, "start_releasing")
	orb_panel.connect("paused", self, "_on_paused")
	orb_panel.set_visible(true, true)

	play_animation(Player.ANIMS.IDLE)
	set_input_enabled(true)
	reload_spots()

func init_orb_levels(name: String) -> Dictionary:
	if get_begin() != get_start():
		name += "/%s" % start_name
	var ORB_LEVELS := { # The number of orbs available at the level start
		"Level2": { Orb.BLUE: 1, Orb.GREEN: 1 },
		"Level10":{ Orb.BLUE: 1 },
		"Level11":{ Orb.GREEN: 1 },
		"Level12":{ Orb.BLUE: 1 },
		"Level23":{ Orb.GREEN: 1 },
		"Level32/End":{ Orb.PURPLE: 1 },
		"Outro":  { Orb.BLUE: 1, Orb.GREEN: 1, Orb.PURPLE: 1, Orb.RED: 1 }
	}
	return ORB_LEVELS.get(name, {})

func init_ocean():
	var path = "res://maps/dist-%s.png" % name
	var texture
	if ResourceLoader.exists(path):
		texture = load(path)
	elif _DEBUG_:
		var map = generate_distmap(true)
		if map:
			map.save_png(path)
			texture = ImageTexture.new()
			texture.create_from_image(map, Texture.FLAG_MIPMAPS)

	var bounds = get_bounds_margin_all(15)
	var center = bounds.position + (bounds.size / Vector3(2,2,2))

	var node = MeshInstance.new(); node.name = "Ocean"
	node.translation = Vector3(center.x-0.25, bounds.position.y-0.1, center.z-0.25)
	node.rotation.x = -PI/2
	add_child(node)

	var mesh = QuadMesh.new()
	mesh.size = Vector2(bounds.size.x, bounds.size.z)
	node.mesh = mesh

	var mat = preload("res://materials/OceanShader.tres")
	assert(mat is ShaderMaterial)
	mat.set_shader_param("dist_map", texture)
	var shore_color = Season.shore_color(season)
	var far_color = Season.far_color(season)
	if ambience == Ambience.NIGHTMARE:
		shore_color = shore_color.darkened(0.85); far_color = far_color.darkened(0.85)
	mat.set_shader_param("shore_color", shore_color)
	mat.set_shader_param("far_color", far_color)
	node.set_surface_material(0, mat)

func init_path_extension(from_start:=true, from_ends:=true):
	var directions = {} # { cell:Vector3 : direction:Vector3 }
	var cells := PoolVector3Array()
	if from_start: cells += PoolVector3Array([get_start()])
	if from_ends: cells += get_ends()
	for cell in cells:
		for neighboor in _neighbors(cell):
			if is_walkable(neighboor):
				assert(not directions.has(cell))
				directions[cell] = cell-neighboor
	for cell in directions:
		_add_extension_path(cell, directions[cell])

func _get_level_bottom():
	var y = 0; for cell in get_used_cells():
		if is_walkable(cell): y = min(y, cell.y)
	return y

func _add_extension_path(from_cell, direction, length=13):
	assert(abs(direction.x+direction.z) == 1 and direction.y == 0)
	for i in range(1, length+1):
		var cell = from_cell + direction * Vector3(i,i,i)
		assert(cell != from_cell)
		set_cell_itemv(cell, PATH_EXT)

		# Add scenery and wave items on path right/left
		var SCENERY_NAME = "Straight-2"
		var item = self.mesh_library.find_item_by_name(SCENERY_NAME); assert(item != -1)
		var WAVE_NAME = "Wave-Straight"
		var wave = self.mesh_library.find_item_by_name(WAVE_NAME); assert(wave != -1)
		var shows_waves = (ambience != Ambience.NIGHTMARE and cell.y == _get_level_bottom()) # Sea level

		var angle = atan2(direction.x, direction.z)
		var orientation = rad2orientation(angle)
		var offset = direction.rotated(UP, PI/2)
		set_cell_itemv(cell + offset, item, orientation)
		if shows_waves:
			set_cell_itemv(cell + offset * Vector3(2,2,2) - Vector3(0,1,0), wave, orientation)

		orientation = rad2orientation(angle+PI)
		offset = direction.rotated(UP, -PI/2)
		set_cell_itemv(cell + offset, item, orientation)
		if shows_waves:
			set_cell_itemv(cell + offset * Vector3(2,2,2) - Vector3(0,1,0), wave, orientation)

var TORCH_PARTICLE_OFFSET = AREA_OFFSET + Vector3(0,0.6,0)
var torch_particles = {} # {Vector3 : TorchParticles}
func setup_torchs():
	for torch in get_torches():
		var TorchParticles = load("res://particles/TorchParticles.tscn")
		var particles = TorchParticles.instance()
		particles.translation = torch + TORCH_PARTICLE_OFFSET
		particles.orb = get_cell_orb(torch)
		add_child(particles)
		particles.emitting = false
		torch_particles[torch] = particles
		var absorbed = not is_torch_light(torch)
		set_cell_absorbed(torch, absorbed, false)

func setup_camera():
	camera.set_default_environment(ambience)
	camera.angle = get_level_angle()
	camera.make_current()

var NODE_OFFSET := AREA_OFFSET # Activable node container offset with underlying cell
var activables := {} # { cell:Vector3 : Activable }
func setup_activables():
	for cell in get_activables() + get_orbs():
		var orb := get_cell_orb(cell)

		# Add only the activable movable part to grid
		var name: String
		if is_door(cell): name = "Door"
		elif is_hole(cell): name = "Hole"
		elif is_lift(cell): name = "Lift"
		elif is_orb(cell): name = "Orb"
		else: continue

		var color := Orb.color(orb, season)
		var activable := Activable.new(name, color, ambience == Ambience.NIGHTMARE)
		add_child(activable); activables[cell] = activable

		# Fix activable position/orientation
		var rot := get_cell_quat(cell)
		activable.transform *= Transform(rot)
		activable.translation = cell + NODE_OFFSET

		# Set cell with inactive mesh
		var absorbed := not can_absorb(cell, orb)
		if is_orb(cell): absorbed = is_orb_picked(cell)

		var inactive = {
			Type_.DOOR_CLOSED: Type.DOOR,
			Type.HOLE: Type_.HOLE_EMPTY,
			Type_.LIFT_UP: Type.LIFT }
		var item := get_cell_itemv(cell)
		var type := _item_type(item)
		if inactive.has(type):
			item = _item_for(inactive[type], orb)
		var orientation := get_cell_item_orientationv(cell)
		set_cell_itemv(cell, item, orientation)

		# Remove lift top and orb from cell mesh
		if is_lift(cell) or is_orb(cell):
			var mesh := self.mesh_library.get_item_mesh(item)
			var surface_name = {
				Orb.BLUE: "Blue", Orb.GREEN: "Green", Orb.PURPLE: "Purple",
				Orb.RED: "Red", Orb.YELLOW: "Yellow", Orb.GRAY: "Gray" }[orb]
			var surface := Helper.get_surface_named(mesh, surface_name); assert(surface != null)
			var mat := mesh.surface_get_material(surface).duplicate()
			mat.flags_transparent = true
			mat.albedo_color.a = 0
			mesh.surface_set_material(surface, mat)

		set_cell_absorbed(cell, absorbed, false)

# Callbacks

var accessible_ends = []
func _on_spots_updated(spots):
	var ends := []
	for spot in spots:
		if spot != get_begin() and (Array(get_ends()).has(spot) or spot == get_start()):
			var end_name = end_name_for(spot); assert(end_name)
			if not accessible_ends.has(spot):
				emit_signal("end_accessible", end_name)
			ends.append(spot)
	accessible_ends = ends

func _get_end_angle(end_index:=0):
	var end = get_ends()[end_index]
	var ext_cell; for neighbor in _neighbors(end):
		if get_cell_itemv(neighbor) == PATH_EXT: ext_cell = neighbor
	assert(ext_cell)
	return atan2(ext_cell.x-end.x, ext_cell.z-end.z) - PI/2

func _on_end_accessible(end_name: String):
	if ambience == Ambience.NIGHTMARE:
		camera.set_ambiant_energy(0.15, 2.0)
		# Move player to end
		var end = get_ends()[get_end_names().find(end_name)]
		move_player(end)
		# Move wolf to end
		var wolf = load("res://models/wolf.tscn").instance()
		add_child(wolf); glide(wolf, get_begin(), end)
		# Add moon light reflect near to end
		var moon = load("res://models/MoonLight.tscn").instance()
		var offset = Vector3(-1.5, _get_level_bottom(), 3.5)
		var angle = _get_end_angle()
		moon.translation = get_start() + offset.rotated(UP, angle) * 0.8
		moon.opacity = 0; add_child(moon)
		var tween = moon.get_node("Tween")
		tween.interpolate_property(moon, "opacity", 0, 1,
			0.5, Tween.TRANS_LINEAR, Tween.EASE_IN); tween.start()

# Pause Menu

func _on_paused():
	toggle_pause()

var pause_menu
func toggle_pause():
	if pause_menu:
		Helper.remove_from_parent(pause_menu)
		pause_menu = null
		get_tree().paused = false
	else:
		pause_menu = load("res://PauseMenu.tscn").instance()
		pause_menu.connect("resumed", self, "toggle_pause")
		pause_menu.connect("restarted", self, "_on_restarted")
		pause_menu.set_sounds_mute(audio_player.muted)
		pause_menu.connect("sounds_toggled", self, "_on_sounds_toggled")
		pause_menu.set_music_mute(music_player.muted)
		pause_menu.connect("music_toggled", self, "_on_music_toggled")
		add_child(pause_menu)
		get_tree().paused = true

func _on_sounds_toggled(enabled):
	audio_player.muted = not enabled

func _on_music_toggled(enabled):
	music_player.muted = not enabled

func _on_restarted():
	emit_signal("game_restarted")

func get_player_cell():
	return round3(player.translation - PLAYER_OFFSET)

func face_player(to):
	var rotation = player.rotation
	player.look_at(to + PLAYER_OFFSET, UP)
	var angle = player.rotation.y - rotation.y
	player.rotation = rotation
	var anim = rotation_anim(angle)
	if anim != null:
		queue_animation(anim)
	else:
		call_deferred("emit_signal", ANIM_DONE_SIGNAL, anim)

func rotation_anim(radians):
	var angle = rad2deg(shortest(radians))
	angle = round(angle / 90) * 90
	var anim
	if angle == 90.0:
		anim = Anim.TURN_LEFT
	elif angle == -90.0:
		anim = Anim.TURN_RIGHT
	elif abs(angle) == 180.0:
		anim = Anim.HALF_TURN
	else:
		assert(abs(angle) < 1e-3)
	return anim

func move_player(to: Vector3):
	var from = get_player_pos()
	if to == from: return # DEBUG (`move_player` should not be called if same position)
	var id = closest_reachable_path_for(Actor.PLAYER, from, to, null, true)
	var path := yield(self, id)[0] as PoolVector3Array
	walk(player, path)
	_on_reaching_cell(to)

func walk(node: Spatial, path: Array):
	set_input_enabled(false)

	face_player(path[1])
	yield(self, ANIM_DONE_SIGNAL)

	var should_run = (path.size() > 3)
	audio_player.play(Sound.RUN if should_run else Sound.WALK)

	var tween = player.get_default_tween()
	tween.start()

	var delay := 0.0
	var tweens := 0
	var from = node.translation
	path.pop_front()
	var index := 0; while true:
		if index >= path.size(): break # Create custom loop to inc `index` into loop

		var anim: int = Anim.RUN if should_run else Anim.WALK
		var cell := path[index] as Vector3
		var to := get_lift_bottom(cell) + PLAYER_OFFSET
		to.y += int(is_lift_up(cell))

		if index == path.size()-1: # Last cell (cannot be turn or stairs)
			pass
		elif is_stairs(cell):
			var ascending = (abs(from.y-to.y) < 1e-3)
			assert(ascending or abs(from.y-(to.y+1)) < 1e-3) # or descending
			anim = Anim.ASCEND if ascending else Anim.DESCEND
			to = path[index+1]+PLAYER_OFFSET
			index += 1
		else: # Straight path or turn
			var next = path[index+1]+PLAYER_OFFSET
			var before = to-from; var after = next-to
			#assert(abs(before.x)+abs(before.z) == 1 and abs(after.x)+abs(after.z) == 1) # DEBUG

			var angle = shortest(atan2(after.x,after.z)-atan2(before.x,before.z))
			var turn_anim = rotation_anim(angle)
			if turn_anim != null: # Turn
				anim = turn_anim
				# Set `to` into turn interior for more natural path
				to = from.linear_interpolate(next, 0.5).linear_interpolate(to, 0.5)
			else: # Straight path
				pass

		if anim == Anim.RUN and index == 0:
			anim = Anim.START
		if anim == Anim.RUN and index == path.size()-1:
			anim = Anim.STOP

		var duration := player.duration(anim)
		tween.interpolate_property(node, "translation", from, to,
			duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, delay); delay += duration
		tweens += 1
		queue_animation(anim)

		from = to; index += 1

	queue_animation(Anim.IDLE)

	for _i in tweens:
		yield(tween, "tween_completed")
	var to = from - PLAYER_OFFSET

	audio_player.stop_sound(Sound.RUN if should_run else Sound.WALK)
	_on_walked(node, to)

func _on_walked(node: Spatial, to: Vector3):
	if to == get_start():
		prints("(!) Player on start:", to)
		_on_level_finished(to)
	else:
		var index := Array(get_ends()).find(to)
		if index != -1:
			prints("(!) Player on end:", ["End #1", "End #2"][index])
			_on_level_finished(to)

	reload_spots()
	check_orb_nearby()
	set_input_enabled(true)

func glide(node, from, to, speed=PLAYER_SPEED*2): # speed in cells per seconds
	var tween = Tween.new()
	add_child(tween); tween.start()
	var id = closest_reachable_path_for(Actor._HOLLOW, from, to, null, true)
	var path := yield(self, id)[0] as PoolVector3Array
	for i in path.size()-2:
		var current = path[i]; if is_lift(current): current.y = get_lift_bottom(current).y + 1
		var next = path[i+1]; if is_lift(next): next.y = get_lift_bottom(next).y + 1
		tween.interpolate_property(node, "translation",
			current + PLAYER_OFFSET, next + PLAYER_OFFSET, 1.0/speed,
			Tween.TRANS_LINEAR, Tween.EASE_IN)

		var angle = atan2(next.x-current.x, next.z-current.z) - PI/2
		var to_angle = node.rotation; to_angle.y += shortest(angle - node.rotation.y)
		tween.interpolate_property(node, "rotation",
			node.rotation, to_angle, 1.0/speed,
			Tween.TRANS_LINEAR, Tween.EASE_IN)
		yield(tween, "tween_completed")
		yield(tween, "tween_completed")
	Helper.remove_from_parent(tween)

func get_end_names() -> Array:
	for level in END_NAMES.keys(): # Use `keys()` to keep sorted
		if filename.get_file().find(level) != -1:
			return END_NAMES[level]
	return END_NAMES["*"]

func end_name_for(cell: Vector3):
	if cell == get_begin():
		pass
	elif cell == get_start():
		return START_NAME
	elif Array(get_ends()).has(cell):
		var index = Array(get_ends()).find(cell)
		return get_end_names()[index]
	return null

func _on_reaching_cell(cell):
	var end_name = end_name_for(cell)
	if end_name:
		emit_signal("end_reached", end_name)

func _on_level_finished(cell):
	if cell == get_begin():
		return
	var end_name = end_name_for(cell); assert(end_name)
	audio_player.play_sound(Sound.LEVEL_END)
	audio_player.stop_sound(Sound.OCEAN)
	emit_signal("finished", end_name)

var event_pos: Vector2
var ray_origin # Vector3?
var ray_target # Vector3?
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		self.event_pos = event.position
		self.ray_origin = camera.project_ray_origin(event.position)
		self.ray_target = ray_origin + camera.project_ray_normal(event.position) * 1_000

func _physics_process(delta):
	if ray_origin != null and ray_target != null:

		var space_state = PhysicsServer.space_get_direct_state(get_world().get_space())
		var hit = space_state.intersect_ray(ray_origin, ray_target)
		# Get selected spot
		if not hit.empty() and hit.collider.is_ray_pickable():
			var to = hit.collider.global_transform.origin - AREA_OFFSET
			to.y -= int(is_lift_up(to))
			move_player(to)
		else: # If no spot selected
			# Find the closest to click
			var closest_spot; var min_distance = INF
			for spot in get_spots():
				var screen_pos := camera.unproject_position(spot)
				var distance = self.event_pos.distance_squared_to(screen_pos)
				if distance < min_distance:
					closest_spot = spot
					min_distance = distance
			# Move the boy on closer spot to him on path to `closest_spot`
			assert(closest_spot != null)
			var path = path_for(Actor.PLAYER, get_player_cell(), closest_spot)
			for cell in path:
				if Array(get_spots()).has(cell):
					move_player(cell); break

		ray_origin = null; ray_target = null

func _unhandled_key_input(event):
	if not event.pressed: return
	match event.scancode:
		KEY_ESCAPE:
			toggle_pause()
		KEY_SPACE: # DEBUG
			if _DEBUG_: reload_spots()

func check_orb_nearby():
	var pos = get_player_pos()
	for cell in _neighbors(pos):
		if is_orb(cell) and not is_orb_picked(cell):
			var orb = get_cell_orb(cell)
			progression.available_orbs.append(orb)
			add_orb_level(orb, 1)
			pick_orb(cell)
			audio_player.play(Sound.TAKE_ORB)

func is_player_on_lift() -> bool:
	return is_lift(get_player_pos())

### Get spots to move player

var _spots # PoolVector3Array?, Cached spots
func get_spots() -> PoolVector3Array:
	if _spots == null:
		reload_spots()
	return _spots

func _get_orb_positions() -> PoolVector3Array: # Returns closest orb positions to player, where it can walk on to pick them
	var cells := PoolVector3Array()
	for cell in get_cells_for(Type.ORB):
		if not is_orb_picked(cell):
			var spot; var distance = INF
			for neighbor in _neighbors(cell):
				var d = get_player_pos().distance_to(neighbor)
				if is_walkable(neighbor) and d < distance:
					distance = d; spot = neighbor
			if spot != null:
				cells.append(spot)
	return cells

func _update_spots():
	var concerns = [get_start()] + Array(get_ends()) + Array(_get_orb_positions())
	concerns.erase(get_begin())
	var spots := []
	for cell in concerns:
		var id := closest_reachable_path_for(Actor.PLAYER, get_player_pos(), cell, null, true)
		var path := Array(yield(self, id)[0] as PoolVector3Array)
		for cell in path:
			if is_lift(cell): spots.append(get_lift_bottom(cell))
		spots.append(path.back())
	Helper.distinct(spots)
	spots.erase(get_player_pos())

	for spot in spots: assert(is_valid(spot) and is_walkable(spot)) # DEBUG

	emit_signal("_spots_updated", PoolVector3Array(spots))

var _reloading := false
func reload_spots():
	if _reloading: return
	call_deferred("_reload_spots"); _reloading = true
func _reload_spots():
	#if not force and not level_animation_player.is_idle(): return # Wait for all animations to finish
	prints("=== Reload Spots ===", "[%s]" % get_player_pos())

	var ts = OS.get_ticks_msec()
	_update_spots()
	_spots = yield(self, "_spots_updated")
	prints("Update spots:", _spots, "(%sms)" % (OS.get_ticks_msec()-ts)) # DEBUG

	disable_all_hotspots()
	for spot in get_spots():
		enable_hotspot(spot, true)

	# Remove start if the player cannot go to previous level
	#for position in []+spots:
	#	if position == start_node.global_transform.origin:
	#		if LevelsMap.new().level_before(get_level_name(), start_name) == null:
	#			spots.erase(position)

	_reloading = false
	update_camera()

var hotspots = []
func enable_hotspot(cell: Vector3, enabled:=true):
	.enable_hotspot(cell, enabled)
	hotspots.append(cell) if enabled else hotspots.erase(cell)
	var position = cell + Vector3(0,1,0)
	add_spot_node(position) if enabled else remove_spot_node(position)

func disable_all_hotspots():
	for spot in []+hotspots:
		enable_hotspot(spot, false)
	assert(hotspots.empty() and spot_nodes.empty())

var _activables := PoolVector3Array()
func get_activables() -> PoolVector3Array:
	if _activables.size() == 0:
		_activables = get_doors() + get_holes() + get_lifts() + get_torches()
	return _activables

func get_absorbables(orb: int) -> PoolVector3Array:
	var cells := PoolVector3Array()
	for cell in get_activables():
		if can_absorb(cell, orb):
			cells.append(cell)
	return cells

func available_orbs() -> PoolIntArray:
	var orbs := PoolIntArray()
	for orb in self.orbs:
		if get_orb_level(orb) > 0: orbs.append(orb)
	return orbs

func get_interactive_cells() -> PoolVector3Array:
	var interactives := get_orbs()
	for cell in get_activables():
		for orb in available_orbs():
			if can_absorb(cell, orb) or can_activate(cell, orb):
				interactives.append(cell)
	return interactives

func update_camera():
	call_deferred("_update_camera")
func _update_camera(): # TODO: Pass player path positions for smooth translation
	if not is_inside_tree(): return

	# Weights for center calculation
	var wplayer := 2.2; var wspot := 1.4
	var wactivable := 1.0; var wpath := 0.8

	var player_pos := get_player_pos()
	var spots := get_spots() + PoolVector3Array([get_start()]) + get_ends()
	spots = PoolVector3Array(Helper.distinct(Array(spots)))
	var activables := get_interactive_cells()

	var center := player_pos * wplayer
	for spot in spots: center += spot * wspot
	for position in activables: center += position * wactivable
	var cells := PoolVector3Array(); for end in get_ends():
		cells += path_for(Actor._HOLLOW, get_start(), end)
	cells = PoolVector3Array(Helper.distinct(Array(cells)))
	for cell in cells: center += cell * wpath

	center /= (wplayer + wspot * spots.size() + wactivable * activables.size() + wpath * cells.size())
	camera.set_position(center)

	var cam := camera.duplicate() as Camera; add_child(cam)
	cam.translation = center
	cam.name = "TempCamera"
	camera.make_current() # Keep main camera current

	cam.size = 4; var panel_width = 60#px
	var screen := Rect2(Vector2(0,0), get_viewport().size).grow_individual(0, 0, -panel_width, 0)
	var targets := PoolVector3Array([player_pos]) + spots + activables + cells; assert(targets.size() > 0)
	# Zoom-out until all `targets` visible
	while true:
		assert(cam.size < 60) # Avoid infinite loop

		var pos := cam.unproject_position(targets[0])
		var frame := Rect2(pos, Vector2(1,1))
		for position in targets:
			frame = frame.expand(cam.unproject_position(position))

		if screen.encloses(frame.grow(60)): break
		cam.size += 1.5

	camera.update_size(max(8, cam.size))
	Helper.remove_from_parent(cam, false)

# Returns the behaviour when `orb` collides with `cell`.
# func behaviour(cell: Vector3, orb: Orb) -> enum Behaviour
func behaviour(cell: Vector3, orb: int) -> int:
	assert(is_valid(cell))
	if can_activate(cell, orb):
		return Behaviour.ABSORBED
	#elif not can_absorb(cell, orb) and not is_torch(cell):
	#	return Behaviour.BOUNCING
	elif (is_door(cell) and is_door_closed(cell) or
		is_hole(cell) and is_hole_empty(cell) or
		is_lift(cell) and is_lift_up(cell)):
		return Behaviour.BOUNCING
	return Behaviour.PASSING

## Orb particles

var PARTICLE_OFFSET := AREA_OFFSET + Vector3(0, 1.48, 0)
var PARTICLE_SPEED := 7.0 if _DEBUG_ else 4.0 # cells per second

class ParticlesNode extends Spatial:

	const ActivableParticles := preload("res://particles/ActivableParticles.gd")

	signal moved(from, to)

	var orb := -1 setget ,get_orb
	func get_orb():
		return particles.orb if particles else -1

	var particles: ActivableParticles setget set_particles
	func set_particles(value: ActivableParticles):
		if particles:
			remove_child(particles)
		particles = value
		add_child(particles)

var moving_particles := 0
var node_paths := {} # { Particle : PoolVector3Array }
## Move particles with matching `orb`, starting at `from` and going to `to` if reachable.
## The optional `end_callback` is called when particles moved, and be like `void a_selector(Orb, Behaviour)`,
##   the `behaviour` param is `PASSING` if particles has reached `to`.
## Returns true if the particle can start moving (unlike bouncing lift).
func move_particles(orb: int, from: Vector3, to: Vector3, end_callback:="") -> bool:
	var id := closest_reachable_path_for(Actor.PARTICLE, from, to, orb, true)
	var path := yield(self, id)[0] as PoolVector3Array

	var particles := preload("res://particles/ActivableParticles.tscn").instance()
	particles.name = "particles"
	particles.season = season; particles.orb = orb
	particles.translation = PARTICLE_OFFSET

	var node := ParticlesNode.new()
	node.particles = particles
	node.translation = from
	add_child(node)
	var tween := Tween.new(); tween.name = "tween"
	node.add_child(tween)

	if is_lift(from): # Absorbing up lift...
		if path.size() == 1: # ...from higher level, so lift is bouncing
			_on_lift_bounced(from, orb)

			to = path_for(Actor._HOLLOW, from, to)[1]
			var destination = from.linear_interpolate(to, 0.3)
			_move_particle(node, destination)
			yield(node, "moved")
			_move_particle(node, from)
			yield(node, "moved")
			particles.emitting = false
			Helper.remove_from_parent(node)

			if end_callback:
				call_deferred(end_callback, orb, Behaviour.BOUNCING)
			return false
		else:
			assert(path[1].y <= path[0].y) # ???: Why?

	assert(not node_paths.has(node))
	node_paths[node] = path

	if _DEBUG_:
		# Check that two particles don't have the same end and distance (until absorbed)
		var dests := {}; for path in node_paths.values(): # DEBUG
			var longest_path := []; for index in range(1, path.size()): # Ignore absorbed cell
				longest_path.append(path[index])
				if can_activate(path[index], orb): break
			var dest = longest_path.back()
			if dests.has(dest): assert(dests[dest] != path.size())
			dests[dest] = longest_path.size()

	_advance_particle(node, end_callback)
	moving_particles += 1

	audio_player.play(Sound.PARTICLES)

	return true

func get_particle_next_cell(node: ParticlesNode, cell: Vector3, step:=1) -> Vector3:
	assert(node_paths.has(node))
	var path = Array(node_paths[node]); var index = path.find(cell)
	return path[index+step] if index != -1 and index+step < path.size() else null

# func particle_behaviour(node: ParticlesNode, orb: Orb, cell: Vector3) -> enum Behaviour
func particle_behaviour(node: ParticlesNode, orb: int, cell: Vector3) -> int:
	var reversed := reversed_particles.has(node)
	var next := get_particle_next_cell(node, cell, -1 if reversed else 1)
	if next == null: # End of path reached
		if can_activate(cell, orb) or cell == get_player_cell():
			return Behaviour.REACHED
		else: # It reaches the computed path, no absorbing can occur
			return Behaviour.BOUNCING

	var path = Array(node_paths[node])
	if path.find(cell) == 0 and reversed: # Bounced back to start
		return Behaviour.ABSORBED # Bouncing back to start

	# Particle passing on down/up lift with same top level
	if is_lift(next) and not can_activate(get_lift_bottom(next), orb) and (
		get_lift_bottom(next).y+int(is_lift_up(next)) == cell.y):
		return Behaviour.PASSING

	assert(is_valid(next))
	return behaviour(next, orb)

# Note: `node` emits "moved" when move animation to `to` finished
func _move_particle(node: ParticlesNode, to: Vector3):
	var from := node.translation
	var tween := node.get_node("tween"); tween.start()
	tween.interpolate_property(node, "translation", from, to,
		1.0 / PARTICLE_SPEED, Tween.TRANS_LINEAR, Tween.EASE_IN)

	var from_ofs := PARTICLE_OFFSET; var to_ofs = PARTICLE_OFFSET
	if is_torch(from) and not can_activate(from, node.orb):
		from_ofs.y += 0.6
	elif is_torch(to) and not can_activate(to, node.orb):
		to_ofs.y += 0.6
	if from_ofs != to_ofs:
		tween.interpolate_property(node.particles, "translation", from_ofs, to_ofs,
			1.0 / PARTICLE_SPEED, Tween.TRANS_LINEAR, Tween.EASE_IN)
		yield(tween, "tween_completed")

	yield(tween, "tween_completed")
	node.emit_signal("moved", from, to)

var reversed_particles := [] # [Particle]
# Move `node` particle following `get_particle_next_cell`,
#   and calls optional `end_callback(Orb, enum Behaviour)` when final destination reached.
func _advance_particle(node: ParticlesNode, end_callback:=""):
	var cell := round3(node.translation); assert(cell != null)
	var behaviour := particle_behaviour(node, node.orb, cell)
	match behaviour:
		Behaviour.ABSORBED, Behaviour.REACHED:
			var destination # Vector3?
			var reversed = reversed_particles.has(node)
			if behaviour == Behaviour.ABSORBED and reversed:
				# Ends by bouncing back to start (re-absorbed by emitter)
				behaviour = Behaviour.BOUNCING
				destination = node_paths[node][0]

			if destination == null:
				var step := -1 if reversed else 1
				destination = get_particle_next_cell(node, cell, step)

			if destination == null:
				destination = cell

			assert(destination != null)

			# Move particle to `destination`
			var offset := -Vector3(0,0.8,0)
			#prints(destination, get_player_cell())
			if destination == get_player_cell():
				offset = Vector3(0,0.25,0)
			_move_particle(node, destination + offset)
			yield(node, "moved")

			# Cleanup particle node
			node_paths.erase(node)
			reversed_particles.erase(node)

			# Notify
			_on_particle_moved(node, node.orb, destination, behaviour)
			if end_callback: call(end_callback, node.orb, behaviour)
			return

		Behaviour.BOUNCING:
			var reversed := reversed_particles.has(node)
			if reversed:
				reversed_particles.erase(node)
			else:
				reversed_particles.append(node)

			# TODO: On bouncing, move to half way to next cell and go back to `from`

		Behaviour.PASSING:
			pass

	var reversed = reversed_particles.has(node)
	var to := get_particle_next_cell(node, cell, -1 if reversed else 1)
	_move_particle(node, to)
	yield(node, "moved")

	if behaviour == Behaviour.BOUNCING:
		_on_particle_bounced(node, node.orb, to)

	_advance_particle(node, end_callback)

func _on_lift_bounced(position: Vector3, orb: int):
	var activable = activables[position]
	activable.play("Lift-bounce")
	yield(activable.get_animation_player(), "animation_finished")

	var up := is_lift_up(position)
	set_lift_up(position, true)

var particle_already_bouncing := false
func _on_particle_bounced(node: ParticlesNode, orb: int, position: Vector3):
	if is_lift_up(position): assert(false) # Ignore for bouncing lifts # TODO: Remove if unused
	if ambience == Ambience.NIGHTMARE: return

	var panel := preload("res://BounceWavePanel.tscn").instance()
	# Place below orbs panel to avoid (transparent) orbs buttons to disappear
	add_child(panel); move_child(panel, orb_panel.get_index())
	if snow: move_child(panel, snow.get_index())

	var center := camera.unproject_position(position + Vector3(0,1,0))
	panel.play_wave(center)
	panel.queue_remove()

	if not particle_already_bouncing: # Ignore next bounces
		particle_already_bouncing = true

		audio_player.play(Sound.BOUNCE)
		yield(panel, "finished")
		emit_signal("player_hurt")
		camera.shake(1.1, 1.4)

# Note: The particle `node` as bounced back to start if behaviour == BOUNCING
func _on_particle_moved(node: ParticlesNode, orb: int, to_pos: Vector3, behaviour: int):
	moving_particles -= 1;
	if moving_particles == 0: all_particles_moved()

	match behaviour:
		Behaviour.REACHED: print("(!) Particle successfully reached end")
		Behaviour.BOUNCING: print("(!) Bounced back to emitter")

	if to_pos == get_player_pos(): # Moved/bounced to player
		add_orb_level(orb)
	else:
		activate(to_pos)

	audio_player.stop_sound(Sound.PARTICLES)
	#node.particles.restart() # DEBUG
	#node.particles.emitting = false
	node.particles.hide()

	var timer := Timer.new(); add_child(timer)
	timer.wait_time = 0.5; timer.autostart = true
	yield(timer, "timeout")
	Helper.remove_from_parent(node)

func all_particles_moved():
	particle_already_bouncing = false


var orbs := {} # { Orb : Int }
func get_orb_level(orb: int) -> int:
	return orbs.get(orb, 0)

func add_orb_level(orb: int, levels:=1):
	orbs[orb] = orbs.get(orb, 0) + levels
	#print("Orb #%s added (= %d)" % [orb, orbs[orb]]) # DEBUG
	orb_panel.orb_levels = orbs
	orb_panel.set_visible(true, true)

func pick_orb(cell: Vector3):
	print("Picking orb")
	# Rotate orb node to player
	var node = activables[cell].get_animated_node(); assert(node)
	node.get_parent().look_at(get_player_cell() + NODE_OFFSET, UP)
	node.get_parent().rotation.y -= PI

	orb_panel.set_visible(true, true)
	set_orb_picked(cell, true)
	update_orb_taken(cell)
	queue_animation(Anim.TAKE)

	reload_spots()

var absorbing_particles := 0
func start_absorbing(orb: int):
	#print("=== Start Absorbing ===")

	var player_pos := get_player_pos()
	if is_lift_up(player_pos):
		var lift := get_lift_bottom(player_pos)
		if can_absorb(lift, orb): # Player on matching lift, only absorb the lift
			absorb(lift)
			add_orb_level(orb)
			set_input_enabled(false)
			return

	absorbing_particles = 0
	var absorbables := get_absorbables(orb)
	if absorbables.size() > 0:

		queue_animation(Anim.ABSORB)
		yield(self, ANIM_DONE_SIGNAL)
		audio_player.play(Sound.ABSORB_ORB)

		for cell in absorbables:
			if move_particles(orb, cell, player_pos, "absorbing_ended"):
				absorb(cell)
				absorbing_particles += 1
		set_input_enabled(false)
	else:
		queue_animation(Anim.ABSORB_NONE)

func absorbing_ended(orb: int, behaviour: int):
	if behaviour == Behaviour.PASSING: # Reaching player
		add_orb_level(orb)
		# TODO: If player is on a down lift, wait for ascending lift animation to update spots

	absorbing_particles -= 1
	if absorbing_particles == 0:
		all_absorbed()

func all_absorbed():
	#print("=== Absorbing Done ===")
	reload_spots()
	set_input_enabled(true)

### Player releasing an orb

func start_releasing(orb: int):
	assert(get_orb_level(orb) > 0)

	var nearest; var min_distance = INF
	if is_player_on_lift() and can_activate(get_player_pos(), orb):
		min_distance = 1; nearest = get_player_cell()
	else:
		var nearests = []
		for cell in get_activables():
			if can_activate(cell, orb):
				var id = closest_reachable_path_for(Actor.PARTICLE, get_player_pos(), cell, orb, true)
				var path = yield(self, id)[0] as PoolVector3Array; assert(path.size() >= 2)
				assert(path is PoolVector3Array)
				var path_to_closest = path_for(Actor._HOLLOW, path[path.size()-2], cell)
				var complete_path = path + path_to_closest
				var distance = complete_path.size()
				if distance < min_distance: nearests = []
				if distance <= min_distance:
					min_distance = distance
					nearests.append(cell)
		if not nearests.empty():
			var min_angle = INF
			for cell in nearests:
				var current = get_player_cell() - PLAYER_OFFSET
				var angle = shortest(player.rotation.y - atan2(current.x-cell.x, current.z-cell.z))
				if angle < min_angle:
					nearest = cell

	print(("Nearest activable: %s" % nearest) if nearest != null else "No activable")

	if nearest != null:
		set_input_enabled(false)

		face_player(nearest)
		yield(self, ANIM_DONE_SIGNAL)

		queue_animation(Anim.RELEASE)
		yield(self, ANIM_DONE_SIGNAL)
		audio_player.play(Sound.RELEASE_ORB)

		add_orb_level(orb, -1)
		if is_player_on_lift() and min_distance == 1: # Player activates the lift is standing on
			assert(nearest == get_player_pos())
			assert(can_activate(nearest, orb))

			activate(get_player_pos())
			yield(self, ANIM_DONE_SIGNAL)
			release_orb_ended(orb, Behaviour.PASSING)
		else:
			move_particles(orb, get_player_pos(), nearest, "release_orb_ended")
	else:
		queue_animation(Anim.RELEASE_NONE)

func release_orb_ended(orb: int, behaviour: int):
	set_input_enabled(true)

func absorb(cell: Vector3):
	#if not can_absorb(cell, -1): return

	#prints("Absorb:", cell)
	var player_on_lift := (is_lift_up(cell) and cell == get_lift_bottom(get_player_pos()))
	set_cell_activated(cell, false)
	if player_on_lift:
		player.blend_enabled = false
		play_animation(Anim.DESCEND_LIFT)
		queue_animation(Anim.IDLE)
		player.translation.y = get_lift_bottom(cell).y + PLAYER_OFFSET.y
		yield(self, ANIM_DONE_SIGNAL)
		player.blend_enabled = true
		_on_walked(player, cell)

func activate(cell: Vector3):
	#if not can_activate(cell, -1): return

	#prints("Activate:", cell)
	var on_lift := is_player_on_lift()
	set_cell_activated(cell, true)
	if is_lift(cell) and on_lift:
		player.blend_enabled = false
		play_animation(Anim.ASCEND_LIFT)
		yield(self, ANIM_DONE_SIGNAL)

		player.translation.y = get_lift_bottom(cell).y + PLAYER_OFFSET.y + 1
		player.reset_skeleton_translation()

		queue_animation(Anim.IDLE)
		player.blend_enabled = true

		_on_walked(player, cell)

func update_orb_taken(cell: Vector3, taken:=true):
	set_cell_absorbed(cell, taken)

func set_cell_activated(cell: Vector3, activated: bool):
	set_cell_absorbed(cell, not activated)

func set_cell_absorbed(cell: Vector3, absorbed, animated=true):
	var orb := get_cell_orb(cell)
	if animated:
		if is_orb(cell) and absorbed != is_orb_picked(cell): return
		if not is_orb(cell) and absorbed != can_absorb(cell, orb): return

	if   is_door(cell): set_door_closed(cell, not absorbed)
	elif is_hole(cell): set_hole_empty(cell, absorbed)
	elif is_lift(cell): set_lift_up(cell, not absorbed)
	elif is_torch(cell): set_torch_light(cell, not absorbed)
	elif is_orb(cell): pass
	else: return

	if is_torch(cell):
		var sound := Sound.TORCH
		audio_player.stop_sound(sound) if absorbed else audio_player.play_sound(sound)
		torch_particles[cell].emitting = not absorbed
		return
	elif not is_orb(cell):
		var sound := Sound.INACTIVATE if absorbed else Sound.ACTIVATE
		if animated: audio_player.play(sound)

	# Play absorb animation (in reverse for activation)
	var activable = activables[cell]
	activable.play_at(0, animated) if absorbed else activable.reverse_at(0, animated)

	if not (is_orb(cell) and absorbed):
		activable.autoplay()

	_on_cell_absorbed(cell, absorbed, animated)

const NIGHTMARE_LIGHT = "nightmare-light"
func _on_cell_absorbed(cell: Vector3, absorbed: bool, animated: bool):
	if ambience == Ambience.NIGHTMARE and not is_orb(cell):
		var activable = activables[cell]
		if not activable.has_node(NIGHTMARE_LIGHT):
			var light := OmniLight.new(); light.name = NIGHTMARE_LIGHT
			light.translation.y += 2.5
			light.light_negative = true
			light.omni_range = 8.5
			light.omni_attenuation = 3.4
			activable.add_child(light)

			var tween := Tween.new(); tween.name = "Tween"
			light.add_child(tween); tween.start()

		var light = activable.get_node(NIGHTMARE_LIGHT)
		light.get_node("Tween").interpolate_property(light, "light_energy",
			light.light_energy, float(absorbed) * 0.5, 1.2,
			Tween.TRANS_LINEAR, Tween.EASE_IN)

	if inactive_particles.has(cell):
		var particles = inactive_particles[cell]
		particles.emitting = absorbed

func _item_for(type: int, orb: int):
	return ITEMS[type][orb]

var rotation_player := AnimationPlayer.new()
func _queue_player_rotation(radians: float, duration: float):
	if not rotation_player.is_inside_tree():
		rotation_player.name = "RotationPlayer"
		add_child(rotation_player)

	#prints("Queue player rotation:", radians)
	var animation := method_animation("_rotate_player_by", [radians, duration])
	animation.length = duration

	var name := "rotation-%d" % randi()
	rotation_player.add_animation(name, animation)
	rotation_player.queue(name)

func _rotate_player_by(radians: float, duration: float):
	var tween := Tween.new(); tween.name = "_RotationTween"
	player.add_child(tween)
	#assert(tween.name == "_RotationTween") # Check one tween is running

	var roty := player.rotation.y
	tween.interpolate_property(player, "rotation",
		player.rotation, player.rotation + Vector3(0, radians, 0),
		duration * 0.99, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")

	player.rotation.y = roty + radians
	Helper.remove_from_parent(tween)

func can_reverse(anim: int) -> bool:
	return false

func queue_animation(anim: int, reversed:=false):
	play_animation(anim, reversed, true)

# Play boy's `anim` animation.
func play_animation(anim: int, reversed:=false, should_queue:=false):
	assert(not reversed or can_reverse(anim))

	cancel_call("_on_player_wait")
	player.stop_waiting()
	
	var anim_player := player.get_animation_player()
	var name := player.name(anim)
	#print("$$$ Queue anim %s%s" % [name, " [reversed]" if reversed else ""]) # DEBUG
	anim_player.queue(name) if should_queue else anim_player.play(name)

	var angle := 0.0; match anim:
		Anim.TURN_LEFT: angle += TAU/4
		Anim.TURN_RIGHT:angle -= TAU/4
		Anim.HALF_TURN: angle += TAU/2
	_queue_player_rotation(angle, player.duration(anim))

	# TODO: Play `anim` if the previous has done or is looping
	yield(anim_player, "animation_finished")
	emit_signal(ANIM_DONE_SIGNAL, anim)
	_on_animation_played()

func _on_animation_played():
	var delay := 5.0 + ceil(randf() * 3.0) # 5-8s
	call_after(delay, "_on_player_wait")

func _on_player_wait():
	var anim_player = player.get_animation_player()
	if not anim_player.is_playing():
		player.play_waiting()


var spot_node: MeshInstance
var spot_nodes := {} # {Vector3 : MeshInstance}
func add_spot_node(position: Vector3):
	remove_spot_node(position)

	if not spot_node:
		var mesh := QuadMesh.new()
		mesh.size = Vector2(0.5, 0.5)

		var mat := SpatialMaterial.new()
		#mat.flags_unshaded = true
		mat.flags_transparent = true
		mat.albedo_color = Season.scenery_color(season)
		mat.albedo_texture = preload("res://textures/hotspot.png")
		mesh.material = mat

		spot_node = MeshInstance.new(); spot_node.name = "PathSpot"
		spot_node.mesh = mesh
		spot_node.rotation.x = -PI/2

		var tween := Tween.new(); tween.name = "Tween"
		spot_node.add_child(tween); tween.start()

	if is_lift_up(position): assert(position.y-1 == get_lift_bottom(position).y) # DEBUG

	var node := spot_node.duplicate() as Spatial
	add_child(node); spot_nodes[position] = node
	node.translation = position + Vector3(0.5, 5e-3, 0.5)
	node.translation.y += int(is_lift_up(position))

	node.scale = Vector3()
	var tween := node.get_node("Tween") as Tween
	tween.start()
	tween.interpolate_property(node, "scale",
		Vector3(), Vector3(1,1,1), 1.0, Tween.TRANS_BOUNCE, Tween.EASE_OUT)

func remove_spot_node(position: Vector3):
	if spot_nodes.has(position):
		var node = spot_nodes[position]
		spot_nodes.erase(position)

		var tween := node.get_node("Tween") as Tween
		tween.start()
		tween.interpolate_property(node, "scale",
			Vector3(1,1,1), Vector3(), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		yield(tween, "tween_completed")

		Helper.remove_from_parent(node)

## Utilities

func round3(v: Vector3) -> Vector3:
	return Vector3(round(v.x), round(v.y), round(v.z))

func shortest(radians: float) -> float:
	return wrapf(radians, -PI, PI)

func method_animation(method: String, args:=[]) -> Animation:
	var animation := Animation.new()
	animation.length = 1e-8 # Set minimum duration to ensure method call
	var track := animation.add_track(Animation.TYPE_METHOD)
	var info := { "method": method, "args": args }
	animation.track_insert_key(track, 0, info)
	return animation

var delay_timers := {} # { method:string : Timer }
func call_after(delay: float, method: String, args:=[]):
	cancel_call(method)
	assert(not delay_timers.has(method))
	var timer := Timer.new(); add_child(timer)
	timer.connect("timeout", self, "_on_call_delayed", [method, args])
	timer.wait_time = max(0.1, delay)
	delay_timers[method] = timer
	timer.start()

func _on_call_delayed(method: String, args:=[]):
	cancel_call(method)
	callv(method, args)

func cancel_call(method: String):
	if delay_timers.has(method):
		var timer = delay_timers[method]
		timer.stop()
		Helper.remove_from_parent(timer)
		delay_timers.erase(method)

## DEPRECATED

func get_player_pos() -> Vector3:
	return get_player_cell()

func get_accessible_spots() -> PoolVector3Array:
	return get_spots()