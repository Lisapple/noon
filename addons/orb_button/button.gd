tool
extends Button

### Signals

signal normal_pressed(button)
signal long_pressed(button)

### Exports

export(int, "None", "Blue", "Green", "Purple", "Red", "Yellow", "Gray") var orb = 0 setget set_orb
func set_orb(value):
	orb = value
	update_interface()

export var orb_level = 0 setget set_orb_level
func set_orb_level(level):
	orb_level = level
	update_interface()

### Constants

const LONG_PRESS_DURATION = 0.6 # seconds
const RADIUS = 34

### Variables

export(float) var progression = 0 setget set_progression
func set_progression(value):
	progression = value
	update_interface()

## Private variables

var can_release = false

var tween = Tween.new()
var progress_node = Polygon2D.new()
var long_press_timer = Timer.new()

func _init():
	rect_min_size = Vector2(56, 56)

func _ready():
	# Keep `progress_node` (relative z = -1) above `SCREEN_TEXTURE` (z = 0) shader param
	VisualServer.canvas_item_set_z_index(self.get_canvas_item(), 2)

	connect("button_down", self, "_on_button_down")
	connect("button_up", self, "_on_button_up")

func _enter_tree():
	flat = true
	enabled_focus_mode = Control.FOCUS_NONE

	add_child(tween)

	progress_node.antialiased = true
	progress_node.z_as_relative = true
	progress_node.z_index = -1 # -1 relative to parent, so absolute z = 1
	progress_node.color = Color(0.25,0.25,0.25)
	add_child(progress_node)

	add_child(long_press_timer)
	long_press_timer.one_shot = true
	long_press_timer.connect("timeout", self, "_on_button_long_pressed")

func _process(delta):
	if long_press_timer and long_press_timer.time_left > 0:
		var progression = (LONG_PRESS_DURATION-long_press_timer.time_left) / LONG_PRESS_DURATION
		set_progression(progression)

func orb_color(orb): # Color orb_color(Int)
	var color; match orb:
		1: color = Color("0F81B6") # Blue
		2: color = Color("06DC74") # Green
		3: color = Color("A15DB2") # Purple
		4: color = Color("E13C49") # Red
		5: color = Color("FFD352") # Yellow
		6: color = Color("777777") # Gray
		_: assert(false) # Notice: Invalid value for `orb`
	color.s *= 1.15
	return color

func get_center():
	var c = rect_size / Vector2(2,2)
	return Vector2(int(c.x), int(c.y))

func update_progress():
	var segments = 24
	var points = []
	var step = TAU / float(segments)
	for i in ceil((segments+1) * progression):
		var angle = i * step - PI / 2
		points.append(Vector2(RADIUS * cos(angle), RADIUS * sin(angle)) + get_center())
	if points.size() <= segments:
		points.append(get_center())
	progress_node.polygon = points

func update_interface():
	can_release = (orb_level and orb_level > 0)
	update_progress()
	self.update()

func _draw():
	var bg_color = orb_color(orb)
	if not can_release:
		bg_color = bg_color.darkened(0.35)
	if disabled:
		bg_color = bg_color.darkened(0.5)
		bg_color.s *= 0.5
	draw_circle(get_center(), 30, bg_color)

	#var margin = 10; var color = orb_color(orb)
	#var background_image = preload("res://textures/orb-background-active.png")
	#draw_texture(background_image, Vector2(margin, margin), color)

	var mask_image = preload("res://textures/orb-mask.png")
	draw_texture(mask_image, Vector2(-1,-1))

	var badge_texture
	if   orb_level == 1: badge_texture = preload("res://textures/badge-1.png") # Note: `load()` not work here
	elif orb_level == 2: badge_texture = preload("res://textures/badge-2.png")
	elif orb_level == 3: badge_texture = preload("res://textures/badge-3.png")
	elif orb_level > 0:
		var font = get_font("font")
		draw_string(font, get_center() - Vector2(10, 0), "(%d)" % orb_level, Color(1,1,1,1))

	if badge_texture:
		var margin = -badge_texture.get_size() / Vector2(2,2);
		draw_texture(badge_texture, get_center() + margin, Color(1,1,1,0.5+int(not disabled)))

func start_long_press_timer():
	stop_long_press_timer()
	long_press_timer.wait_time = LONG_PRESS_DURATION
	long_press_timer.start()
	progress_node.modulate.a = 1
	progress_node.position = Vector2(0,0)
	progress_node.scale = Vector2(1,1)

func stop_long_press_timer():
	long_press_timer.stop()

func _on_button_down():
	start_long_press_timer()

func _on_button_long_pressed():
	stop_long_press_timer()
	emit_signal("long_pressed", self)

	var duration = 0.3
	tween.interpolate_property(progress_node, "modulate", Color(1,1,1), Color(1,1,1, 0),
		duration, Tween.TRANS_LINEAR, Tween.EASE_IN)
	var scale = 1.3
	tween.interpolate_property(progress_node, "scale", Vector2(1,1), Vector2(scale, scale),
		duration, Tween.TRANS_LINEAR, Tween.EASE_IN)
	var offset = -get_center() * Vector2(scale-1, scale-1)
	tween.interpolate_property(progress_node, "position", Vector2(0,0), offset,
		duration, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()

func _on_button_up():
	if long_press_timer.get_time_left() > 0:
		emit_signal("normal_pressed", self)
	stop_long_press_timer()
	progress_node.modulate.a = 0
	set_progression(0)
