## Added to `GameGridMap.gd` from `init_torchs()` and used when torch is on.
extends Spatial

var nightmare := false
var orb: int = Orb.GRAY
func set_orb(value: int):
	orb = value
	nightmare = (orb == Orb.GRAY)
	if is_inside_tree():
		_update_particles()

var emitting: bool setget set_emitting, is_emitting
func is_emitting() -> bool:
	return emitting
func set_emitting(value: bool):
	emitting = value
	$Particles.emitting = emitting and not nightmare
	$Particles/NightmareParticles.emitting = emitting and nightmare
	$CrackerParticles.emitting = value

func _ready():
	var mat := $Particles.process_material as ParticlesMaterial
	$Particles.process_material = mat.duplicate(true)
	_update_particles()

func _update_particles():
	assert(orb)
	var color := Orb.color(orb); color.a = 0.5
	
	var mat := $Particles.process_material as ParticlesMaterial
	var gradient := (mat.color_ramp as GradientTexture).gradient
	assert(gradient.get_point_count() == 5)
	gradient.set_color(0, color)
	gradient.set_color(1, color)
	
	var cmat := $CrackerParticles.process_material as ParticlesMaterial
	gradient = (cmat.color_ramp as GradientTexture).gradient
	assert(gradient.get_point_count() == 2)
	gradient.set_color(0, color)