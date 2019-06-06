extends Panel

signal absorbed(orb)
signal released(orb)
signal paused

var orb_levels := {} setget set_orb_levels, get_orb_levels
func get_orb_levels() -> Dictionary:
	return orb_levels
func set_orb_levels(levels: Dictionary):
	orb_levels = levels
	_update_buttons()

onready var buttons := {
	Orb.BLUE: $"Blue Orb Button",
	Orb.GREEN: $"Green Orb Button",
	Orb.PURPLE: $"Purple Orb Button",
	Orb.RED: $"Red Orb Button",
	Orb.YELLOW: $"Yellow Orb Button",
}
onready var pause_button := $"Pause Button"

var enabled := true setget set_enabled, is_enabled
func is_enabled() -> bool:
	return enabled
func set_enabled(value: bool):
	enabled = value
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

	for button in buttons.values():
		button.disabled = not value

var ambience := Ambience.DEFAULT setget set_ambience
func set_ambience(value: int):
	ambience = value
	_update_buttons()
func is_nightmare() -> bool:
	return (ambience == Ambience.NIGHTMARE)

func _ready():
	VisualServer.canvas_item_set_z_index(self.get_canvas_item(), 1)
	name = "OrbPanel"
	set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	set_visible(false)

	for orb in buttons:
		buttons[orb].connect("normal_pressed", self, "_on_button_pressed", [orb])
		buttons[orb].connect("long_pressed", self, "_on_button_long_pressed", [orb])

func _on_button_pressed(button, orb):
	if is_nightmare(): orb = Orb.GRAY
	if orb_levels.get(orb, 0) > 0:
		emit_signal("released", orb)

func _on_button_long_pressed(button, orb):
	if is_nightmare(): orb = Orb.GRAY
	emit_signal("absorbed", orb)

func _on_pause_pressed():
	emit_signal("paused")

func _update_button(button, level): # void _update_orb_button(Button, Int?)
	button.visible = (level != null)
	button.orb_level = level if level else 0

func _update_buttons():
	if buttons == null: return # Not loaded yet

	if is_nightmare():
		var level = orb_levels.get(Orb.GRAY, 0)
		for button in buttons.values():
			button.orb = Orb.GRAY
			button.orb_level = level
	else:
		for orb in buttons:
			var button = buttons[orb]; button.orb = orb
			_update_button(button, orb_levels.get(orb))
	_layout()

func _layout():
	if not buttons: return
	var height := 0.0
	for button in buttons.values():
		if button.visible:
			height = button.rect_position.y + button.rect_size.y + 10

	var screen_size := get_viewport_rect().size
	rect_size.y = max(220, 10 + height + 20) # Extra bottom margin for pause button
	set_begin(Vector2(margin_left, -rect_size.y / 2))

func set_visible(enabled: bool, animated:=false):
	if not is_inside_tree(): return

	var was_enabled := visible
	var sum := 0; for orb in orb_levels: sum += int(orb_levels.has(orb))
	enabled = enabled and (sum > 0)
	var force := (visible != enabled)
	visible = enabled
	_layout()

	var duration := 0.35 if animated else 1e-5
	var screen_width := get_viewport_rect().size.x
	var from := screen_width - (rect_size.x if was_enabled else 0.0)
	var to := screen_width - (rect_size.x if enabled else 0.0)
	var y := rect_position.y
	if to != rect_position.x or force:
		$Tween.interpolate_property(self, "rect_position", Vector2(from, y), Vector2(to, y),
			duration, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()

func update_orb_levels(levels: Dictionary): # levels : {Orb : Int}
	var animated := bool(orb_levels.empty() != levels.empty())
	set_visible(not levels.empty(), animated)
	orb_levels = levels
	_update_buttons()