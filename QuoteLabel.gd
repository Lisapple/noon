extends Label

class QuoteFont extends DynamicFont:

	func _init(size):
		font_data = preload("res://fonts/plume.ttf")
		self.size = size

var font setget set_font
func set_font(value):
	font = value
	add_font_override("font", font)

var tween := Tween.new()
var texture1 := TextureRect.new()
var texture2 := TextureRect.new()

func _init():
	self.align = Label.ALIGN_CENTER
	self.valign = Label.ALIGN_CENTER
	self.autowrap = true

func get_size() -> Vector2:
	return Vector2(margin_left, margin_top) + rect_size

func _ready():
	add_child(tween)

	texture1.set_anchors_preset(Control.PRESET_WIDE)
	add_child(texture1)
	texture2.set_anchors_preset(Control.PRESET_WIDE)
	add_child(texture2)

	_setup_viewport(get_size())
	var blurs := [0.5, 1.0, 1.7, 2.5, 3.8]
	for blur in blurs:
		_render_texture(blur)
	_cleanup_viewport()

	self.modulate.a = 0

func fade_in(duration:=0.45):
	_show(true, duration)

func fade_out(duration:=0.35):
	_show(false, duration)

var duration := 0.0
func _update(elapsed: float):
	var textures = blur_textures.values()
	var count = textures.size()
	var step := duration / float(count)

	var index1 := int(elapsed / step)
	texture1.texture = textures[min(index1, count-1)]

	var index2 := int(elapsed / step + 0.5)
	texture2.texture = textures[min(index2, count-1)]

func _show(show: bool, duration: float):
	tween.stop_all()

	self.duration = float(duration)
	var from := duration * int(show)
	tween.interpolate_method(self, "_update", from, duration - from,
		duration, Tween.TRANS_LINEAR, Tween.EASE_IN)

	# Self blending
	var from_color := Color(1,1,1, int(not show))
	var to_color := Color(1,1,1, int(show))
	tween.interpolate_property(self, "modulate", from_color, to_color,
		duration, Tween.TRANS_LINEAR, Tween.EASE_IN)

	# Label blending
	var delay := duration * 0.5 * int(show)
	self_modulate = from_color
	tween.interpolate_property(self, "self_modulate", from_color, to_color,
		duration * 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN, delay)

	# Textures blending
	from_color.a *= 0.35; to_color.a *= 0.35
	delay = duration * 0.7 * int(show)
	texture1.modulate = to_color
	tween.interpolate_property(texture1, "modulate", to_color, from_color,
		duration * 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN, delay)

	texture2.modulate = to_color
	tween.interpolate_property(texture2, "modulate", to_color, from_color,
		duration * 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN, delay)

	tween.start()

var blur_textures = { 0 : null } # { float : Image }
func _render_texture(blur):
	var texture := ImageTexture.new()
	texture.create_from_image(render(blur))
	blur_textures[blur] = texture

## Generating texture

var viewport
var canvas
func _setup_viewport(size):
	var vs := VisualServer
	var transparent := true

	# Create and setup viewport
	viewport = vs.viewport_create()
	vs.viewport_attach_to_screen(viewport, Rect2(-size, size)) # Out of main screen
	vs.viewport_set_global_canvas_transform(viewport, Transform2D(0, -rect_position))
	vs.viewport_set_size(viewport, size.x, size.y)
	vs.viewport_set_update_mode(viewport, VisualServer.VIEWPORT_UPDATE_ALWAYS)
	vs.viewport_set_transparent_background(viewport, transparent)
	vs.viewport_set_hdr(viewport, false) # To render to RGBA (and not RGBH)
	vs.viewport_set_vflip(viewport, true)
	vs.viewport_set_active(viewport, true)

	# Create parent canvas
	canvas = vs.canvas_create()
	vs.viewport_attach_canvas(viewport, canvas)

func render(blur = 0, bg_color = Color(1,1,1,0)):
	assert(is_inside_tree())

	var vs := VisualServer
	var size := get_size()

	# Add background color
	var ci := vs.canvas_item_create()
	vs.canvas_item_add_rect(ci, Rect2(0,0,size.x,size.y), bg_color)
	vs.canvas_item_set_parent(ci, canvas)

	# Add label
	var li := self.get_canvas_item()
	vs.canvas_item_set_parent(li, canvas)
	vs.canvas_item_set_z_as_relative_to_parent(li, true)
	vs.canvas_item_set_z_index(li, 1)

	# Add blur shader
	var sid := vs.shader_create()
	vs.shader_set_code(sid, """
		shader_type canvas_item;
		render_mode blend_premul_alpha;
		uniform vec4 color : hint_color;
		uniform float blur = 0.0;
		void fragment() {
			COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur * 0.6);
			COLOR.a = sqrt(length(COLOR.rgb)) * 3.0;
			COLOR.rgb = color.rgb;
		}
	""")
	var mid := vs.material_create()
	var color := get_color("font_color") if has_color_override("font_color") else Color(1,1,1)
	vs.material_set_param(mid, "color", color);
	vs.material_set_param(mid, "blur", blur);
	vs.material_set_shader(mid, sid)

	var ci2 := vs.canvas_item_create()
	vs.canvas_item_add_rect(ci2, Rect2(0,0,size.x,size.y), Color(0,0,0,0))
	vs.canvas_item_set_material(ci2, mid)
	vs.canvas_item_set_z_as_relative_to_parent(ci2, true)
	vs.canvas_item_set_z_index(ci2, 2)
	vs.canvas_item_set_parent(ci2, canvas)

	# Render to texture
	var tex := vs.viewport_get_texture(viewport)
	get_tree().iteration(0); vs.draw(false)
	var image := vs.texture_get_data(tex)
	assert(image and image.get_format() == Image.FORMAT_RGBA8)

	# Clean up
	vs.canvas_item_clear(ci); vs.free_rid(ci)
	vs.free_rid(sid); vs.free_rid(mid)
	vs.canvas_item_clear(ci2); vs.free_rid(ci2)

	return image

func _cleanup_viewport():
	assert(viewport)
	var vs := VisualServer

	vs.viewport_remove_canvas(viewport, canvas)
	vs.free_rid(canvas); canvas = null
	vs.viewport_detach(viewport)
	vs.free_rid(viewport); viewport = null

	vs.canvas_item_set_parent(self.get_canvas_item(), self.get_canvas())
