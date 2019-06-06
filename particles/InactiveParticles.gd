extends Particles

func set_orb(orb: int, season=Season.SUMMER):
	var mesh: QuadMesh = draw_pass_1.duplicate()
	mesh.material = mesh.material.duplicate()
	(mesh.material as SpatialMaterial).albedo_color = Orb.particle_color(orb, season)
	draw_pass_1 = mesh; 