extends Particles

func set_orb(orb, season=Season.SUMMER):
	draw_pass_1 = draw_pass_1.duplicate(); assert(draw_pass_1 is QuadMesh)
	draw_pass_1.material = draw_pass_1.material.duplicate(); assert(draw_pass_1.material is SpatialMaterial)
	draw_pass_1.material.albedo_color = Orb.particle_color(orb, season)