tool
extends Camera

var _DEBUG_ = Helper.DEBUG_ENABLED

const Ambience = preload("res://data/Ambience.gd")

const CAMERA_SCALE = 10.0
const CAMERA_NEAR = 0.01
const CAMERA_FAR = 50.0

# The offset of the camera with the player; The camera is always looking at the player.
const CAMERA_OFFSET_ = Vector3(8, 8, 8)
# The speed factor when recentering camera; < 0.5 for slow > 1.5 for fast, default to 1 (normal)
const CAMERA_SPEED_FACTOR = 1.0

var tween := Tween.new()
var light1 := DirectionalLight.new()
var light2 := DirectionalLight.new()
var light3 := DirectionalLight.new()

func set_default_environment(ambience=Ambience.DEFAULT):
	var env := Environment.new()
	# Ambient light
	env.ambient_light_color = Color(1,1,1)

	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07,0.07,0.07)

	match ambience:
		Ambience.NIGHTMARE:
			# Ambient light
			env.ambient_light_energy = 0
			# Glow
			env.glow_enabled = true
			env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
			var glow_levels = [4, 5, 6]; for level in 7:
				env.set_glow_level(level, true)#glow_levels.has(level))
			env.glow_hdr_threshold = 0.4
			env.glow_intensity = 1.0
			# Reflections
			#env.ss_reflections_enabled = true
			#env.ss_reflections_max_steps = 16
			#env.ss_reflections_fade_in = 1
			#env.ss_reflections_fade_out = 0.5
			#env.ss_reflections_depth_tolerance = 1
			#env.ss_reflections_roughness = true
			# Adjustments
			env.adjustment_enabled = true
			env.adjustment_brightness = 0.4
			env.adjustment_contrast = 1.1
			env.adjustment_saturation = 0.2
		Ambience.DEFAULT:
			# Ambient light
			env.ambient_light_energy = 0.15
			# Glow
			env.glow_enabled = false
			# Reflections
			env.ss_reflections_enabled = false
			# Adjustments
			env.adjustment_enabled = false
			#env.adjustment_brightness = 1.1
			#env.adjustment_contrast = 1.2
			#env.adjustment_saturation = 1
	environment = env

	light1.shadow_enabled = (ambience != Ambience.NIGHTMARE)
	for light in [light1, light2, light3]:
		var gray := 0.5 if ambience == Ambience.NIGHTMARE else 1.0
		light.light_color = Color(gray,gray,gray)

func _init():
	add_child(tween)

	light1.light_energy = 0.75
	light1.rotation_degrees = Vector3(-30, 60, 45)
	light1.shadow_enabled = true
	light1.directional_shadow_mode = DirectionalLight.SHADOW_ORTHOGONAL
	light1.directional_shadow_blend_splits = true
	light1.directional_shadow_normal_bias = 0.1
	light1.directional_shadow_depth_range = DirectionalLight.SHADOW_DEPTH_RANGE_STABLE
	add_child(light1)

	light2.light_energy = 0.45
	light2.rotation_degrees = Vector3(0, 10, 10)
	add_child(light2)

	light3.light_energy = 0.15
	light3.light_negative = true
	light3.light_color = Color(1,1,1)
	light3.rotation_degrees = Vector3(25, -50, 0)
	add_child(light3)

	near = CAMERA_NEAR; far = CAMERA_FAR
	size = CAMERA_SCALE
	projection = PROJECTION_ORTHOGONAL
	translation = CAMERA_OFFSET_

	set_default_environment()

func _enter_tree():
	translation = _camera_offset()
	if _DEBUG_:
		get_viewport().msaa = Viewport.MSAA_DISABLED

func _ready():
	look_at(Vector3(0,0,0), Vector3.UP)

func set_ambiant_energy(energy: float, duration:=0.0):
	tween.interpolate_property(environment, "ambient_light_energy",
		environment.ambient_light_energy, energy,
		duration, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()

var angle := 0.0 setget set_angle
func set_angle(value: float):
	var pos := translation - _camera_offset()
	angle = value
	translation = pos + _camera_offset()
	if is_inside_tree():
		look_at(pos, Vector3.UP)

func _camera_offset() -> Vector3:
	return CAMERA_OFFSET_.rotated(Vector3.UP, angle)

func set_position(position: Vector3, speed:=2.85): # Speed is average in m/s
	var pos := translation - _camera_offset()
	if position == pos: return
	look_at(pos, Vector3.UP)

	var duration := 1.2
	var distance := pos.distance_to(position)
	if distance > 0.5:
		duration = pow(distance, 0.4) / max(0.1, speed * CAMERA_SPEED_FACTOR)

	tween.interpolate_property(self, "translation", pos+_camera_offset(), position+_camera_offset(),
		duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	tween.start()

func update_size(to_scale: float, animated:=true):
	to_scale = clamp(to_scale, 5, 15)
	if animated:
		tween.interpolate_property(self, "size", size, to_scale,
			0.75, Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.start()
	else:
		size = to_scale

func shake(duration:=0.6, magnitude:=0.9):
	var y := Vector3.UP * magnitude
	tween.interpolate_property(self, "translation", translation, translation + y,
		0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.interpolate_property(self, "translation", translation + y, translation,
		duration-0.1, Tween.TRANS_ELASTIC, Tween.EASE_OUT, 0.1)
	tween.start()
