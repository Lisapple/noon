extends Node

enum {
	ABSORB_ORB, RELEASE_ORB, TAKE_ORB, LEVEL_END,
	BOUNCE, ACTIVATE, INACTIVATE, THUNDER,
	WALK, RUN, PARTICLES, TORCH, HEART_BEAT, RAIN, OCEAN
}
const ACTIVATION = ACTIVATE # DEPRECATED
static func NAMES(): return {
	# Player sounds
	ABSORB_ORB: "absorb",
	RELEASE_ORB: "release",
	TAKE_ORB: "take-orb",
	LEVEL_END: "level_end",

	# Level sounds
	BOUNCE: "bounce",
	ACTIVATE: "activation",
	INACTIVATE: "activation",
	THUNDER: "thunder",

	# Looping sounds
	WALK: "walking",
	RUN: "walking",
	PARTICLES: "particles",
	TORCH: "torch",
	HEART_BEAT: "heart_beat",
	RAIN: "rain",
	OCEAN: ""
}

static func all():
	return NAMES().keys()

static func name(sound):
	return NAMES()[sound]
