extends Node

enum { SUMMER, AUTUMN, WINTER, SPRING }

static func name(season):
	return { SUMMER:"Summer", AUTUMN:"Autumn", WINTER:"Winter", SPRING:"Spring" }[season]

static func scenery_color(season):
	return Color({ SUMMER: "306e0a", AUTUMN: "7e521b", WINTER: "f4f7ff", SPRING: "605e5e" }[season])

static func path_color(season):
	return Color({ SUMMER: "2b6409", AUTUMN: "724a18", WINTER: "dde0e8", SPRING: "575555" }[season])

static func plants_color(season):
	return Color({ SUMMER: "2b6409", AUTUMN: "70450e", WINTER: "3d2400", SPRING: "1f1609" }[season])

static func shore_color(season):
	return Color({ SUMMER: "a5ffff", AUTUMN: "cdf5ff", WINTER: "f0f8ff", SPRING: "fff5f0" }[season])

static func far_color(season):
	return Color({ SUMMER: "6393e3", AUTUMN: "7a93a4", WINTER: "959da3", SPRING: "a69997" }[season])

static func _level_number(name):
	if name == "TestMap": return 0 # DEBUG
	if name == "Intro": return 0 # Summer
	elif name == "Outro": return 99 # Spring
	elif name.begins_with("Nightmare"): return 99 # Spring
	else:
		return int(Helper.first_match("Level(\\d{1,2})", name))

static func for_level(name, orbs):
	print(Season.name(_for_level(name, orbs)))
	return _for_level(name, orbs)

static func _for_level(name, orbs):
	var number = _level_number(name)
	if number >= 45:
		return SPRING
	elif number >= 30 and orbs.has(Orb.RED):
		return WINTER
	elif number >= 20:
		return AUTUMN
	return SUMMER

#static func light_color(season):
#	return {SUMMER:Color("120024"), AUTUMN:Color("243E75"), WINTER:Color("26333E"), SPRING:Color("170C40")}[season]

#static func water_color(season, day=true):
#	var colors = {SUMMER:Color("309DFC"), AUTUMN:Color("65B8FF"), WINTER:Color("95BADA"), SPRING:Color("A6CCED")}
#	if not day: colors = {SUMMER:Color("223A4F"), AUTUMN:Color("2E4254"), WINTER:Color("3E4E5C"), SPRING:Color("41576B")}
#	return colors[season]

#static func get_water_params(season, day=true, raining=false): # {String : Variant} get_water_params(enum Season, Bool?, Bool?)
#	# { peaks height, horizontal displacement, overall speed }
#	var values = {SUMMER:[0.8,0.15,1.8], AUTUMN:[0.65,0.12,1.2], WINTER:[0.4,0.1,0.8], SPRING:[1.2,0.2,1.2]}[season]
#	if raining:
#		values[0] *= 1.4; values[1] *= 1.2; values[2] *= 1.6 # Height, displacement and speed
#	return {"base":water_color(season, day), "height":values[0], "displacement":values[1], "speed":values[2]}
