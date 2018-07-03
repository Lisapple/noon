extends Particles

var gradient = Gradient.new()

var season = Season.SUMMER setget set_season
func set_season(value):
	season = value
	if orb != null:
		_update_gradient()

var orb setget set_orb
func set_orb(value):
	orb = value
	_update_gradient()

func _init():
	gradient.add_point(0, Color(0,0,0))
	gradient.add_point(0, Color(0,0,0))
	assert(gradient.get_point_count() == 4)

	var ramp = GradientTexture.new()
	ramp.width = 8; ramp.gradient = gradient
	process_material.color_ramp = ramp

func _update_gradient():
	gradient.offsets = [
		0, 0.33, 0.66, 1
	]
	gradient.colors = [
		Orb.color(orb, season),
		Orb.color(orb, season),
		Color(1,1,1, 0.5),
		Color(1,1,1, 0)
	]