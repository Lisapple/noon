extends MeshInstance

var opacity = 1.0 setget set_opacity
func set_opacity(value):
	opacity = value
	get_surface_material(0).set_shader_param("alpha", value)

func _ready():
	pass
