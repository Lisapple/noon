tool
extends Panel

var z_index = 20
var fullscreen = true

func set_blur(value):
	if material:
		material.set_shader_param("blur", value)

func _ready():
	VisualServer.canvas_item_set_z_index(get_canvas_item(), z_index)
	if fullscreen:
		rect_size = get_viewport_rect().size
		set_anchors_preset(PRESET_WIDE)

	material = ShaderMaterial.new()

	material.shader = Shader.new()
	material.shader.code = """
		shader_type canvas_item;

		uniform float brightness = 0.8;
		uniform float contrast = 0.3;
		uniform float saturation = 0.4;
		uniform float blur = 3.4;

		void fragment() {
			vec3 color = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur).rgb;
			float grayscale = length(color * vec3(0.299, 0.587, 0.114));
			color += (1.0 - saturation) * (grayscale - color);
			color = (color - 0.5) * contrast + 0.5;
			COLOR.rgb = color * brightness - 0.25;
			COLOR.a = 1.0;
		}"""

func add_child(node):
	.add_child(node)
	if node is Control:
		VisualServer.canvas_item_set_parent(node.get_canvas_item(), get_canvas_item())
		VisualServer.canvas_item_set_z_as_relative_to_parent(node.get_canvas_item(), true)
		VisualServer.canvas_item_set_z_index(node.get_canvas_item(), 1)