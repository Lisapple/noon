## Added to `GameGridMap.gd` from `init_torchs()` and used when torch is on.
extends Spatial

var nightmare = false
var orb
func set_orb(value):
	orb = value
	nightmare = (orb == Orb.GRAY)
	if is_inside_tree():
		_update_particles()

var emitting setget set_emitting, is_emitting
func is_emitting():
	return emitting
func set_emitting(value):
	emitting = value
	$Particles.emitting = emitting and not nightmare
	$Particles/NightmareParticles.emitting = emitting and nightmare

func _ready():
	var mat = $Particles.process_material.duplicate(true)
	$Particles.process_material = mat
	_update_particles()

func _update_particles():
	assert(orb)
	var color = Orb.color(orb); color.a = 0.5
	assert($Particles.process_material is ParticlesMaterial)
	assert($Particles.process_material.color_ramp is GradientTexture)
	var gradient = $Particles.process_material.color_ramp.gradient
	assert(gradient.get_point_count() == 5)
	gradient.set_color(0, color)
	gradient.set_color(1, color)
